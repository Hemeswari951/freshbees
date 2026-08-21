-- ============================================================================
-- THIRAA — Multi-Vendor Fashion & Beauty Marketplace
-- Fresh Consolidated Schema (PostgreSQL) — FINAL UPDATED VERSION
-- Includes: base schema + product_colors + fixed clothing attributes
--           + EAV product_attributes + tags + variant fixes
-- Run this ONCE against a NEW empty database.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- ADMIN
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE admins (
    admin_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    full_name VARCHAR(150),
    role VARCHAR(50) DEFAULT 'SuperAdmin',
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    login_at TIMESTAMP,
    logout_at TIMESTAMP,
    is_logged_in BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- CUSTOMERS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    first_name      VARCHAR(150) NOT NULL,
    last_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) UNIQUE,
    password        VARCHAR(255) NOT NULL,
    phone           VARCHAR(20)  UNIQUE,
    profile_image   TEXT,
    gender          VARCHAR(20),
    city            VARCHAR(100),
    state           VARCHAR(100),
    date_of_birth   DATE,
    is_verified     BOOLEAN      DEFAULT FALSE,
    is_blocked      BOOLEAN      DEFAULT FALSE,
    last_login      TIMESTAMP,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT customer_has_identifier
        CHECK (email IS NOT NULL OR phone IS NOT NULL)
);
-- ─────────────────────────────────────────────────────────────────────────
-- CATEGORIES  →  Men, Women, Kids, Beauty
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL,
    category_image TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO categories (category_name, category_image) VALUES
('Men', NULL),
('Women', NULL),
('Kids', NULL),
('Beauty', NULL);

-- ─────────────────────────────────────────────────────────────────────────
-- SHOPS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE shops (
    shop_id SERIAL PRIMARY KEY,
    shop_name VARCHAR(150) NOT NULL,
    shop_logo TEXT,
    shop_banner TEXT,
    shop_description TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    is_blocked BOOLEAN DEFAULT FALSE,
    blocked_reason TEXT,
    blocked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE shop_categories (
    shop_category_id SERIAL PRIMARY KEY,
    shop_id INT NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
    category_id INT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(shop_id, category_id)
);

-- ─────────────────────────────────────────────────────────────────────────
-- SHOP OWNERS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE shop_owners (
    shop_owner_id SERIAL PRIMARY KEY,
    shop_id INT REFERENCES shops(shop_id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE,
    password_hash TEXT NOT NULL,
    profile_image TEXT,
    last_login TIMESTAMP,
    is_logged_in BOOLEAN DEFAULT FALSE,
    login_at TIMESTAMP,
    logout_at TIMESTAMP,
    is_password_changed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- SHOP BANK DETAILS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE shop_bank_details (
    bank_detail_id SERIAL PRIMARY KEY,
    shop_id INT UNIQUE REFERENCES shops(shop_id) ON DELETE CASCADE,
    account_number VARCHAR(30) NOT NULL,
    account_holder_name VARCHAR(150),
    bank_name VARCHAR(150) NOT NULL,
    ifsc_code VARCHAR(15) NOT NULL,
    gst_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- SHOP SETTINGS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE shop_settings (
    setting_id SERIAL PRIMARY KEY,
    shop_id INT UNIQUE REFERENCES shops(shop_id) ON DELETE CASCADE,
    commission_rate NUMERIC(5,2) DEFAULT 10.00,
    activate_immediately BOOLEAN DEFAULT TRUE,
    send_welcome_email BOOLEAN DEFAULT TRUE,
    allow_product_uploads BOOLEAN DEFAULT TRUE,
    enable_payout_requests BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- BRANDS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE brands (
    brand_id SERIAL PRIMARY KEY,
    brand_name VARCHAR(100) UNIQUE NOT NULL,
    brand_logo TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- PRODUCTS  (now includes common clothing attributes + new-arrival flag)
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    shop_id INT REFERENCES shops(shop_id) ON DELETE CASCADE,
    category_id INT REFERENCES categories(category_id),
    brand_id INT REFERENCES brands(brand_id),
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    description TEXT,
    sub_category VARCHAR(100),

    -- common clothing attributes (frequently filtered/searched)
    fabric VARCHAR(100),
    pattern VARCHAR(50),
    fit_type VARCHAR(50),
    sleeve_type VARCHAR(50),
    neck_type VARCHAR(50),
    occasion VARCHAR(50),
    wash_care TEXT,
    country_of_origin VARCHAR(100) DEFAULT 'India',

    mrp NUMERIC(10,2),
    price NUMERIC(10,2) NOT NULL,
    discount_percent INT DEFAULT 0,

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- PRODUCT ATTRIBUTES (EAV) — category-specific extra details only
-- e.g. Pockets, Closure Type, Heel Height, Sleeve Cuff, etc.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE product_attributes (
    attribute_id   SERIAL PRIMARY KEY,
    product_id     INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    label          VARCHAR(50) NOT NULL,
    value          VARCHAR(255) NOT NULL,
    display_order  INT DEFAULT 1,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- TAGS — for search & filter (e.g. "party wear", "summer collection")
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE tags (
    tag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE product_tags (
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    tag_id INT NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, tag_id)
);

-- ─────────────────────────────────────────────────────────────────────────
-- PRODUCT COLORS — each product can have multiple colors, each color has
-- its own photos and its own set of size variants.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE product_colors (
    product_color_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    color_name VARCHAR(50) NOT NULL,
    color_hex VARCHAR(7),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- PRODUCT IMAGES — tied to a specific color
-- image_type: front | back | side | zoom
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE product_images (
    image_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    product_color_id INT REFERENCES product_colors(product_color_id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_type VARCHAR(20) DEFAULT 'front',
    display_order INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- PRODUCT VARIANTS — stock per size, per color.
-- color comes ONLY from product_colors (no duplicate text column).
-- unique_variant prevents adding the same size twice under one color.
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE product_variants (
    variant_id SERIAL PRIMARY KEY,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    product_color_id INT REFERENCES product_colors(product_color_id) ON DELETE CASCADE,
    size VARCHAR(10) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    -- Approach 1: NULL by default -> falls back to products.price / mrp.
    -- Only set when this size+color combo needs a different price
    -- (e.g. XXL costs more, or this color is a premium pick).
    price NUMERIC(10,2),
    mrp NUMERIC(10,2),
    stock_quantity INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_variant UNIQUE (product_color_id, size)
);

-- ─────────────────────────────────────────────────────────────────────────
-- WISHLIST
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE wishlist (
    wishlist_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (customer_id, product_id)
);

-- ─────────────────────────────────────────────────────────────────────────
-- SHOPPING BAG
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE shopping_bag (
    bag_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    variant_id INT REFERENCES product_variants(variant_id),
    quantity INT DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- ADDRESSES
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'India',
    pincode VARCHAR(10),
    address_type VARCHAR(20),
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- ORDERS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    address_id INT REFERENCES addresses(address_id),
    total_amount NUMERIC(10,2) NOT NULL,
    payment_method VARCHAR(50),
    payment_status VARCHAR(30) DEFAULT 'Pending',
    order_status VARCHAR(50) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- ORDER ITEMS — per-shop status
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    shop_id INT REFERENCES shops(shop_id),
    product_id INT REFERENCES products(product_id),
    variant_id INT REFERENCES product_variants(variant_id),
    quantity INT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    item_status VARCHAR(30) DEFAULT 'Processing',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- PAYOUTS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE payouts (
    payout_id SERIAL PRIMARY KEY,
    shop_id INT REFERENCES shops(shop_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL,
    method VARCHAR(50) DEFAULT 'Bank Transfer',
    status VARCHAR(30) DEFAULT 'Pending',
    order_count INT DEFAULT 0,
    reference_number VARCHAR(100),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE TABLE payout_items (
    payout_item_id SERIAL PRIMARY KEY,
    payout_id INT REFERENCES payouts(payout_id) ON DELETE CASCADE,
    order_item_id INT REFERENCES order_items(order_item_id)
);

-- ─────────────────────────────────────────────────────────────────────────
-- REVIEWS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- MIGRATION: prevent a customer from submitting more than one review per
-- product. Run this once against the existing database.
-- ============================================================================

ALTER TABLE reviews
    ADD CONSTRAINT unique_customer_product_review UNIQUE (customer_id, product_id);


-- ─────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    notification_type VARCHAR(30),
    admin_id INT REFERENCES admins(admin_id),
    shop_owner_id INT REFERENCES shop_owners(shop_owner_id),
    order_id INT REFERENCES orders(order_id),
    title VARCHAR(255),
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ─────────────────────────────────────────────────────────────────────────
-- OTP VERIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────
CREATE TABLE otp_verifications (
    id              SERIAL PRIMARY KEY,
    identifier      VARCHAR(255) NOT NULL,
    portal          VARCHAR(20)  NOT NULL,
    purpose         VARCHAR(30)  NOT NULL,
    otp_code        VARCHAR(255) NOT NULL,
    is_verified     BOOLEAN      DEFAULT false,
    attempts        INT          DEFAULT 0,
    expires_at      TIMESTAMP    NOT NULL,
    created_at      TIMESTAMP    DEFAULT NOW(),
    CONSTRAINT unique_active_otp UNIQUE (identifier, portal)
);


CREATE TABLE refresh_tokens (
  refresh_token_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  portal VARCHAR(20) NOT NULL CHECK (portal IN ('customer', 'shop_owner')),
  token_hash TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_refresh_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_user_portal ON refresh_tokens(user_id, portal);
-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX idx_products_shop ON products(shop_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_product_attributes_product ON product_attributes(product_id);
CREATE INDEX idx_product_colors_product ON product_colors(product_id);
CREATE INDEX idx_product_images_color ON product_images(product_color_id);
CREATE INDEX idx_product_images_product ON product_images(product_id);
CREATE INDEX idx_product_variants_product ON product_variants(product_id);
CREATE INDEX idx_product_variants_color ON product_variants(product_color_id);
CREATE INDEX idx_order_items_shop ON order_items(shop_id);
CREATE INDEX idx_order_items_status ON order_items(item_status);
CREATE INDEX idx_payouts_shop ON payouts(shop_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);

-- ============================================================================
-- VIEWS — computed on the fly, never stored
-- ============================================================================

-- -- Average rating per product
-- CREATE VIEW product_ratings AS
-- SELECT
--     p.product_id,
--     COALESCE(AVG(r.rating), 0)::NUMERIC(3,2) AS avg_rating,
--     COUNT(r.review_id) AS review_count
-- FROM products p
-- LEFT JOIN reviews r ON r.product_id = p.product_id
-- GROUP BY p.product_id;

-- -- Average rating per shop = average of its products' average ratings
-- CREATE VIEW shop_ratings AS
-- SELECT
--     s.shop_id,
--     COALESCE(AVG(pr.avg_rating), 0)::NUMERIC(3,2) AS avg_rating,
--     SUM(pr.review_count) AS total_reviews
-- FROM shops s
-- LEFT JOIN products p ON p.shop_id = s.shop_id
-- LEFT JOIN product_ratings pr ON pr.product_id = p.product_id
-- GROUP BY s.shop_id;

-- -- Per-product total stock (sum across all color/size variants)
-- CREATE VIEW product_stock AS
-- SELECT
--     product_id,
--     COALESCE(SUM(stock_quantity), 0) AS total_stock
-- FROM product_variants
-- GROUP BY product_id;

-- -- Effective price per variant — resolves the Approach 1 override:
-- -- uses the variant's own price/mrp if set, otherwise falls back to
-- -- the product's base price/mrp.
-- CREATE VIEW variant_effective_price AS
-- SELECT
--     pv.variant_id,
--     pv.product_id,
--     pv.product_color_id,
--     pv.size,
--     COALESCE(pv.price, p.price) AS effective_price,
--     COALESCE(pv.mrp, p.mrp) AS effective_mrp
-- FROM product_variants pv
-- JOIN products p ON p.product_id = pv.product_id;

-- -- Per-shop summary stats — for Shop Detail stat cards / Shops grid
-- CREATE VIEW shop_stats AS
-- SELECT
--     s.shop_id,
--     COUNT(DISTINCT p.product_id) AS total_products,
--     COUNT(DISTINCT oi.order_item_id) AS total_orders,
--     COALESCE(SUM(oi.price * oi.quantity), 0)::NUMERIC(12,2) AS total_revenue
-- FROM shops s
-- LEFT JOIN products p ON p.shop_id = s.shop_id
-- LEFT JOIN order_items oi ON oi.shop_id = s.shop_id
-- GROUP BY s.shop_id;