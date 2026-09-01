const pool = require('../../config/db');

const LOW_STOCK_THRESHOLD = 5;

function stockStatus(totalStock) {
  const stock = Number(totalStock) || 0;

  if (stock <= 0) return 'Out of stock';
  if (stock <= LOW_STOCK_THRESHOLD) return 'Only few left';

  return 'In stock';
}

// -----------------------------------------------------------------------------
// DISCOUNT
// -----------------------------------------------------------------------------
// discount_percent is derived from mrp and price.
// It is NOT stored in the database.
// -----------------------------------------------------------------------------

const DISCOUNT_SQL = `
  CASE
    WHEN p.mrp IS NULL
      OR p.mrp <= 0
      OR p.mrp <= p.price
    THEN 0
    ELSE ROUND(((p.mrp - p.price) / p.mrp) * 100)::INT
  END
`;

// -----------------------------------------------------------------------------
// FILTER JOINS
// -----------------------------------------------------------------------------
// These are used by product-list APIs so Flutter receives:
//
// sizes  -> ["S", "M", "L", "XL"]
// colors -> ["Black", "White", "Blue"]
// rating -> 4.5
//
// These values are required by the Flutter filter panel.
// -----------------------------------------------------------------------------

const FILTER_JOINS = `
  LEFT JOIN (
    SELECT
      pc.product_id,
      ARRAY_AGG(DISTINCT pv.size) AS sizes
    FROM product_variants pv
    JOIN product_colors pc
      ON pc.product_color_id = pv.product_color_id
    GROUP BY pc.product_id
  ) sizes_agg
    ON sizes_agg.product_id = p.product_id

  LEFT JOIN (
    SELECT
      product_id,
      ARRAY_AGG(DISTINCT color_name) AS colors
    FROM product_colors
    GROUP BY product_id
  ) colors_agg
    ON colors_agg.product_id = p.product_id

  LEFT JOIN (
    SELECT
      product_id,
      AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY product_id
  ) rating_agg
    ON rating_agg.product_id = p.product_id
`;

const FILTER_SELECT_COLS = `
  COALESCE(
    sizes_agg.sizes,
    ARRAY[]::text[]
  ) AS sizes,

  COALESCE(
    colors_agg.colors,
    ARRAY[]::text[]
  ) AS colors,

  COALESCE(
    rating_agg.avg_rating,
    0
  )::float AS rating
`;

// -----------------------------------------------------------------------------
// REVIEW COUNT JOIN
// -----------------------------------------------------------------------------
// Separate from FILTER_JOINS above because FILTER_JOINS' rating_agg only
// computes avg_rating (used for the `rating` field / filter panel).
// findAllPublicProducts already had its own inline `rv` join for
// review_count — pulled out here so findPublicProductsByShop and
// findPublicProductsBySearch can reuse it instead of duplicating it.
// Without this, shop-page and search-result products always came back
// with reviewCount = 0 even when reviews existed.
// -----------------------------------------------------------------------------

const REVIEW_JOIN = `
  LEFT JOIN (
    SELECT
      product_id,
      COUNT(*) AS review_count,
      AVG(rating) AS avg_rating
    FROM reviews
    GROUP BY product_id
  ) rv
    ON rv.product_id = p.product_id
`;

const REVIEW_SELECT_COLS = `
  COALESCE(
    rv.review_count,
    0
  ) AS review_count
`;

// -----------------------------------------------------------------------------
// FIND ALL PUBLIC PRODUCTS
// -----------------------------------------------------------------------------
// Used for:
// Home
// Men
// Women
// Kids
// Beauty
// All
// Subcategory filtering
// Price filtering
// Sorting
//
// Example:
//
// /products
// /products?category=Men
// /products?category=Women&subCategory=Saree
// /products?category=Men&subCategory=Shirt
// -----------------------------------------------------------------------------

async function findAllPublicProducts({
  category,
  subCategory,
  minPrice,
  maxPrice,
  sortBy,
} = {}) {
  const values = [];

  const conditions = [
    `p.is_active = true`,
    `s.is_blocked = false`,
  ];

  // ---------------------------------------------------------------------------
  // CATEGORY FILTER
  // ---------------------------------------------------------------------------
  if (
    category &&
    category.trim() !== '' &&
    category.trim().toLowerCase() !== 'all'
  ) {
    values.push(category.trim().toLowerCase());

    const idx = values.length;

    conditions.push(`
      LOWER(cat.category_name) = $${idx}
    `);
  }

  // ---------------------------------------------------------------------------
  // SUBCATEGORY FILTER
  // ---------------------------------------------------------------------------
  if (subCategory && subCategory.trim() !== '') {
    const normalizedSubCategory = subCategory
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, '');

    values.push(normalizedSubCategory);

    const idx = values.length;

    conditions.push(`
      (
        LOWER(
          REGEXP_REPLACE(
            COALESCE(p.sub_category, ''),
            '[\\s-]+',
            '',
            'g'
          )
        ) = $${idx}

        OR EXISTS (
          SELECT 1
          FROM product_tags pt
          JOIN tags t
            ON t.tag_id = pt.tag_id
          WHERE pt.product_id = p.product_id
            AND LOWER(
              REGEXP_REPLACE(
                t.tag_name,
                '[\\s-]+',
                '',
                'g'
              )
            ) = $${idx}
        )
      )
    `);
  }

  // ---------------------------------------------------------------------------
  // MIN PRICE
  // ---------------------------------------------------------------------------
  if (minPrice !== undefined && minPrice !== '') {
    values.push(Number(minPrice));

    conditions.push(`
      p.price >= $${values.length}
    `);
  }

  // ---------------------------------------------------------------------------
  // MAX PRICE
  // ---------------------------------------------------------------------------
  if (maxPrice !== undefined && maxPrice !== '') {
    values.push(Number(maxPrice));

    conditions.push(`
      p.price <= $${values.length}
    `);
  }

  // ---------------------------------------------------------------------------
  // SORTING
  // ---------------------------------------------------------------------------
  let orderBy = 'p.created_at DESC';

  if (sortBy === 'price_asc') {
    orderBy = 'p.price ASC';
  }

  if (sortBy === 'price_desc') {
    orderBy = 'p.price DESC';
  }

  if (sortBy === 'discount') {
    orderBy = `${DISCOUNT_SQL} DESC`;
  }

  if (sortBy === 'popularity') {
    orderBy = 'COALESCE(rv.review_count, 0) DESC';
  }

  if (sortBy === 'rating') {
    orderBy = 'COALESCE(rv.avg_rating, 0) DESC';
  }

  // ---------------------------------------------------------------------------
  // QUERY
  // ---------------------------------------------------------------------------
  const { rows } = await pool.query(
    `
    SELECT

      p.product_id,
      p.product_name,
      p.description,

      p.mrp,
      p.price,

      ${DISCOUNT_SQL} AS discount_percent,

      p.shop_id,
      s.shop_name,

      p.category_id,
      cat.category_name,

      p.sub_category,

      b.brand_name,

      COALESCE(
        img.image_url,
        NULL
      ) AS thumbnail,

      COALESCE(
        v.total_stock,
        0
      ) AS total_stock,

      COALESCE(
        rv.review_count,
        0
      ) AS review_count,

      COALESCE(
        rv.avg_rating,
        0
      ) AS avg_rating,

      ${FILTER_SELECT_COLS}

    FROM products p

    JOIN shops s
      ON s.shop_id = p.shop_id

    LEFT JOIN categories cat
      ON cat.category_id = p.category_id

    LEFT JOIN brands b
      ON b.brand_id = p.brand_id

    -- -------------------------------------------------------------------------
    -- FIRST IMAGE / THUMBNAIL
    -- -------------------------------------------------------------------------

    LEFT JOIN LATERAL (
      SELECT
        pi.image_url

      FROM product_images pi

      JOIN product_colors pc
        ON pc.product_color_id = pi.product_color_id

      WHERE pc.product_id = p.product_id

      ORDER BY
        pc.created_at ASC,

        CASE pi.image_type
          WHEN 'front' THEN 0
          ELSE 1
        END,

        pi.display_order ASC

      LIMIT 1

    ) img
      ON true

    -- -------------------------------------------------------------------------
    -- TOTAL STOCK
    -- -------------------------------------------------------------------------

    LEFT JOIN (
      SELECT
        product_id,
        SUM(stock_quantity) AS total_stock

      FROM product_variants
      
      GROUP BY product_id

    ) v
      ON v.product_id = p.product_id

    -- -------------------------------------------------------------------------
    -- REVIEW SUMMARY
    -- -------------------------------------------------------------------------

    LEFT JOIN (
      SELECT
        product_id,
        COUNT(*) AS review_count,
        AVG(rating) AS avg_rating

      FROM reviews

      GROUP BY product_id

    ) rv
      ON rv.product_id = p.product_id

    -- -------------------------------------------------------------------------
    -- SIZE / COLOR / RATING FILTER DATA
    -- -------------------------------------------------------------------------

    ${FILTER_JOINS}

    WHERE ${conditions.join(' AND ')}

    ORDER BY ${orderBy}
    `,
    values
  );

  return rows;
}

// -----------------------------------------------------------------------------
// SINGLE PRODUCT DETAIL
// -----------------------------------------------------------------------------
async function findPublicProductById(productId) {
  const { rows } = await pool.query(
    `
    SELECT

      p.product_id,
      p.product_name,
      p.description,

      p.sub_category,

      p.fabric,
      p.pattern,
      p.fit_type,
      p.sleeve_type,
      p.neck_type,
      p.occasion,
      p.wash_care,
      p.country_of_origin,

      p.mrp,
      p.price,

      ${DISCOUNT_SQL} AS discount_percent,

      p.is_active,

      p.shop_id,
      s.shop_name,
      s.is_blocked AS shop_is_blocked,

      p.category_id,
      cat.category_name,

      b.brand_name

    FROM products p

    JOIN shops s
      ON s.shop_id = p.shop_id

    LEFT JOIN categories cat
      ON cat.category_id = p.category_id

    LEFT JOIN brands b
      ON b.brand_id = p.brand_id

    WHERE p.product_id = $1
    `,
    [productId]
  );

  const product = rows[0];

  if (!product) {
    return null;
  }

  if (!product.is_active) {
    return null;
  }

  if (product.shop_is_blocked) {
    return null;
  }

  // ---------------------------------------------------------------------------
  // COLORS
  // ---------------------------------------------------------------------------
  const colorRows = await pool.query(
    `
    SELECT
      product_color_id,
      color_name,
      color_hex

    FROM product_colors

    WHERE product_id = $1

    ORDER BY created_at ASC
    `,
    [productId]
  );

  const colors = [];

  // ---------------------------------------------------------------------------
  // IMAGES + VARIANTS FOR EACH COLOR
  // ---------------------------------------------------------------------------
  for (const color of colorRows.rows) {
    const images = await pool.query(
      `
      SELECT
        image_id,
        image_url,
        image_type,
        display_order

      FROM product_images

      WHERE product_color_id = $1

      ORDER BY
        CASE image_type
          WHEN 'front' THEN 0
          WHEN 'back' THEN 1
          WHEN 'side' THEN 2
          WHEN 'zoom' THEN 3
          WHEN '360' THEN 4
          ELSE 5
        END,

        display_order ASC
      `,
      [color.product_color_id]
    );

    const variants = await pool.query(
      `
      SELECT

        v.variant_id,
        v.product_color_id,
        v.size,
        v.stock_quantity,

        COALESCE(
          v.price,
          p.price
        ) AS price,

        COALESCE(
          v.mrp,
          p.mrp
        ) AS mrp

      FROM product_variants v

      JOIN products p
        ON p.product_id = v.product_id

      WHERE v.product_color_id = $1

      ORDER BY v.variant_id
      `,
      [color.product_color_id]
    );

    colors.push({
      ...color,
      images: images.rows,
      variants: variants.rows,
    });
  }

  // ---------------------------------------------------------------------------
  // TAGS
  // ---------------------------------------------------------------------------
  const tags = await pool.query(
    `
    SELECT
      t.tag_id,
      t.tag_name

    FROM product_tags pt

    JOIN tags t
      ON t.tag_id = pt.tag_id

    WHERE pt.product_id = $1

    ORDER BY t.tag_name
    `,
    [productId]
  );

  // ---------------------------------------------------------------------------
  // ATTRIBUTES
  // ---------------------------------------------------------------------------
  const attributes = await pool.query(
    `
    SELECT
      attribute_id,
      label,
      value,
      display_order

    FROM product_attributes

    WHERE product_id = $1

    ORDER BY
      display_order ASC,
      attribute_id ASC
    `,
    [productId]
  );

  // ---------------------------------------------------------------------------
  // REVIEWS
  // ---------------------------------------------------------------------------
  const reviews = await pool.query(
    `
    SELECT
      review_id,
      customer_id,
      rating,
      review_text,
      created_at

    FROM reviews

    WHERE product_id = $1

    ORDER BY created_at DESC
    `,
    [productId]
  );

  // ---------------------------------------------------------------------------
  // TOTAL STOCK
  // ---------------------------------------------------------------------------
  const totalStock = colors.reduce(
    (sum, color) => {
      return (
        sum +
        color.variants.reduce(
          (variantSum, variant) => {
            return variantSum + Number(variant.stock_quantity || 0);
          },
          0
        )
      );
    },
    0
  );

  return {
    ...product,

    total_stock: totalStock,

    colors: colors,

    tags: tags.rows,

    attributes: attributes.rows,

    reviews: reviews.rows,
  };
}

// -----------------------------------------------------------------------------
// PRODUCTS BY SHOP
// -----------------------------------------------------------------------------
async function findPublicProductsByShop(shopId) {
  const { rows } = await pool.query(
    `
    SELECT

      p.product_id,
      p.product_name,
      p.description,

      p.mrp,
      p.price,

      ${DISCOUNT_SQL} AS discount_percent,

      p.shop_id,
      s.shop_name,

      p.category_id,
      cat.category_name,

      p.sub_category,

      b.brand_name,

      COALESCE(
        img.image_url,
        NULL
      ) AS thumbnail,

      COALESCE(
        v.total_stock,
        0
      ) AS total_stock,

      ${REVIEW_SELECT_COLS},

      ${FILTER_SELECT_COLS}

    FROM products p

    JOIN shops s
      ON s.shop_id = p.shop_id

    LEFT JOIN categories cat
      ON cat.category_id = p.category_id

    LEFT JOIN brands b
      ON b.brand_id = p.brand_id

    -- -------------------------------------------------------------------------
    -- THUMBNAIL
    -- -------------------------------------------------------------------------

    LEFT JOIN LATERAL (
      SELECT
        pi.image_url

      FROM product_images pi

      JOIN product_colors pc
        ON pc.product_color_id = pi.product_color_id

      WHERE pc.product_id = p.product_id

      ORDER BY
        pc.created_at ASC,

        CASE pi.image_type
          WHEN 'front' THEN 0
          ELSE 1
        END,

        pi.display_order ASC

      LIMIT 1

    ) img
      ON true

    -- -------------------------------------------------------------------------
    -- STOCK
    -- -------------------------------------------------------------------------

    LEFT JOIN (
      SELECT
        product_id,
        SUM(stock_quantity) AS total_stock

      FROM product_variants

      GROUP BY product_id

    ) v
      ON v.product_id = p.product_id

    -- -------------------------------------------------------------------------
    -- REVIEW COUNT
    -- -------------------------------------------------------------------------

    ${REVIEW_JOIN}

    -- -------------------------------------------------------------------------
    -- SIZE / COLOR / RATING
    -- -------------------------------------------------------------------------

    ${FILTER_JOINS}

    WHERE
      p.is_active = true
      AND s.is_blocked = false
      AND p.shop_id = $1

    ORDER BY p.created_at DESC
    `,
    [shopId]
  );

  return rows;
}

// -----------------------------------------------------------------------------
// SEARCH PRODUCTS
// -----------------------------------------------------------------------------
async function findPublicProductsBySearch(searchQuery) {
  const { rows } = await pool.query(
    `
    SELECT

      p.product_id,
      p.product_name,
      p.description,

      p.mrp,
      p.price,

      ${DISCOUNT_SQL} AS discount_percent,

      p.shop_id,
      s.shop_name,

      p.category_id,
      cat.category_name,

      p.sub_category,

      b.brand_name,

      COALESCE(
        img.image_url,
        NULL
      ) AS thumbnail,

      COALESCE(
        v.total_stock,
        0
      ) AS total_stock,

      ${REVIEW_SELECT_COLS},

      ${FILTER_SELECT_COLS}

    FROM products p

    JOIN shops s
      ON s.shop_id = p.shop_id

    LEFT JOIN categories cat
      ON cat.category_id = p.category_id

    LEFT JOIN brands b
      ON b.brand_id = p.brand_id

    -- -------------------------------------------------------------------------
    -- THUMBNAIL
    -- -------------------------------------------------------------------------

    LEFT JOIN LATERAL (
      SELECT
        pi.image_url

      FROM product_images pi

      JOIN product_colors pc
        ON pc.product_color_id = pi.product_color_id

      WHERE pc.product_id = p.product_id

      ORDER BY
        pc.created_at ASC,

        CASE pi.image_type
          WHEN 'front' THEN 0
          ELSE 1
        END,

        pi.display_order ASC

      LIMIT 1

    ) img
      ON true

    -- -------------------------------------------------------------------------
    -- STOCK
    -- -------------------------------------------------------------------------

    LEFT JOIN (
      SELECT
        product_id,
        SUM(stock_quantity) AS total_stock

      FROM product_variants

      GROUP BY product_id

    ) v
      ON v.product_id = p.product_id

    -- -------------------------------------------------------------------------
    -- REVIEW COUNT
    -- -------------------------------------------------------------------------

    ${REVIEW_JOIN}

    -- -------------------------------------------------------------------------
    -- FILTER DATA
    -- -------------------------------------------------------------------------

    ${FILTER_JOINS}

    WHERE
      p.is_active = true
      AND s.is_blocked = false

      AND (
        p.product_name ILIKE $1

        OR p.sub_category ILIKE $1

        OR EXISTS (
          SELECT 1

          FROM product_tags pt

          JOIN tags t
            ON t.tag_id = pt.tag_id

          WHERE pt.product_id = p.product_id

            AND t.tag_name ILIKE $1
        )
      )

    ORDER BY p.created_at DESC
    `,
    [`%${searchQuery}%`]
  );

  return rows;
}

// -----------------------------------------------------------------------------
// FILTER OPTIONS
// -----------------------------------------------------------------------------
async function findFilterOptions() {
  const colorsResult = await pool.query(
    `
    SELECT DISTINCT
      pc.color_name

    FROM product_colors pc

    JOIN products p
      ON p.product_id = pc.product_id

    JOIN shops s
      ON s.shop_id = p.shop_id

    WHERE
      p.is_active = true
      AND s.is_blocked = false

    ORDER BY pc.color_name
    `
  );

  const sizesResult = await pool.query(
    `
    SELECT DISTINCT
      pv.size

    FROM product_variants pv

    JOIN product_colors pc
      ON pc.product_color_id = pv.product_color_id

    JOIN products p
      ON p.product_id = pc.product_id

    JOIN shops s
      ON s.shop_id = p.shop_id

    WHERE
      p.is_active = true
      AND s.is_blocked = false

    ORDER BY pv.size
    `
  );

  return {
    colors: colorsResult.rows.map(
      (row) => row.color_name
    ),

    sizes: sizesResult.rows.map(
      (row) => row.size
    ),
  };
}

// -----------------------------------------------------------------------------
// EXPORTS
// -----------------------------------------------------------------------------

module.exports = {
  stockStatus,

  findAllPublicProducts,

  findPublicProductsByShop,

  findPublicProductsBySearch,

  findPublicProductById,

  findFilterOptions,
};