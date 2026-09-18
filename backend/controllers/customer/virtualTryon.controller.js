const fs = require("fs");
const path = require("path");
const { randomUUID } = require("crypto");

const productService = require("../../services/customer/product.service");
const tryonProfileModel = require("../../models/customer/tryonProfileModel");

const UPLOAD_ROOT = path.join(__dirname, "..", "..", "uploads");
const GENERATED_DIR = path.join(UPLOAD_ROOT, "tryon", "generated");

function normalizeUploadUrl(url) {
  if (!url || typeof url !== "string") return null;

  try {
    const parsed = new URL(url);
    return parsed.pathname;
  } catch (_) {
    return url;
  }
}

function uploadPathToDisk(url) {
  const normalized = normalizeUploadUrl(url);
  if (!normalized || !normalized.startsWith("/uploads/")) {
    return null;
  }

  const relativePath = normalized.replace(/^\/uploads\//, "");
  const resolved = path.resolve(UPLOAD_ROOT, relativePath);

  if (!resolved.startsWith(path.resolve(UPLOAD_ROOT))) {
    return null;
  }

  return resolved;
}

function contentTypeFor(filePath) {
  const ext = path.extname(filePath).toLowerCase();

  if (ext === ".jpg" || ext === ".jpeg") return "image/jpeg";
  if (ext === ".webp") return "image/webp";
  return "image/png";
}

function pickProductImage(product, requestedImageUrl) {
  console.log(
    "[pickProductImage] Requested image URL:",
    requestedImageUrl
  );

  // ==================================================
  // 1. Try the image URL sent from Flutter
  // ==================================================

  if (requestedImageUrl) {
    const requestedPath =
      uploadPathToDisk(requestedImageUrl);

    console.log(
      "[pickProductImage] Requested image path:",
      requestedPath
    );

    if (
      requestedPath &&
      fs.existsSync(requestedPath)
    ) {
      console.log(
        "[pickProductImage] Using requested product image"
      );

      return requestedPath;
    }

    console.log(
      "[pickProductImage] Requested image does not exist"
    );
  }

  // ==================================================
  // 2. Get product images from database
  // ==================================================

  const images = (product.colors || [])
    .flatMap(
      (color) => color.images || []
    )
    .filter(
      (image) => image && image.image_url
    );

  console.log(
    "[pickProductImage] Product images:",
    images
  );

  if (images.length === 0) {
    console.log(
      "[pickProductImage] No product images found"
    );

    return null;
  }

  // ==================================================
  // 3. Prefer FRONT image
  // ==================================================

  const frontImage =
    images.find(
      (image) =>
        image.image_type?.toLowerCase() ===
        "front"
    );

  if (frontImage) {
    const frontPath =
      uploadPathToDisk(
        frontImage.image_url
      );

    console.log(
      "[pickProductImage] Front image path:",
      frontPath
    );

    if (
      frontPath &&
      fs.existsSync(frontPath)
    ) {
      return frontPath;
    }
  }

  // ==================================================
  // 4. Try any non-360 image
  // ==================================================

  const normalImage =
    images.find(
      (image) =>
        image.image_type?.toLowerCase() !==
        "360"
    );

  if (normalImage) {
    const normalPath =
      uploadPathToDisk(
        normalImage.image_url
      );

    console.log(
      "[pickProductImage] Normal image path:",
      normalPath
    );

    if (
      normalPath &&
      fs.existsSync(normalPath)
    ) {
      return normalPath;
    }
  }

  // ==================================================
  // 5. Try first image
  // ==================================================

  const firstImage = images[0];

  const firstPath =
    uploadPathToDisk(
      firstImage.image_url
    );

  console.log(
    "[pickProductImage] First image path:",
    firstPath
  );

  if (
    firstPath &&
    fs.existsSync(firstPath)
  ) {
    return firstPath;
  }

  return null;
}

async function callOpenAIImageEdit({ customerPhotoPath, productImagePath, product, profile }) {
  if (!process.env.OPENAI_API_KEY) {
    const error = new Error("OPENAI_API_KEY is not configured on the backend");
    error.statusCode = 500;
    throw error;
  }

  // Read file contents
  const customerPhotoBuffer = await fs.promises.readFile(customerPhotoPath);
  const productImageBuffer = await fs.promises.readFile(productImagePath);

  // Build prompt
  const prompt = [
    "Create a realistic virtual try-on image.",
    "Use the first input image as the customer reference.",
    "Use the second input image as the exact garment/product reference.",
    `Dress the customer in the selected product: ${product.product_name}.`,
    profile?.height
  ? `Customer height: ${profile.height} cm.`
  : "",

profile?.weight
  ? `Customer weight: ${profile.weight} kg.`
  : "",

profile?.size
  ? `Saved size preference: ${profile.size}.`
  : "",
    "Preserve the customer's face, body pose, skin tone, and background as much as possible.",
    "Replace only the clothing area needed for the selected product.",
    "Keep the garment color, pattern, neckline, sleeve type, and fabric details close to the product image.",
    "Do not add text, logos, watermarks, price labels, or extra people.",
  ]
    .filter(Boolean)
    .join(" ");

  console.log("[callOpenAIImageEdit] Sending request to OpenAI API...");
  console.log("[callOpenAIImageEdit] Prompt:", prompt);

  // Use native FormData if available (Node 18+), otherwise use form-data package
  let form;
  if (typeof FormData !== "undefined") {
    form = new FormData();
    form.append("model", process.env.OPENAI_IMAGE_MODEL || "gpt-image-1");
    form.append("size", "1024x1536");
    form.append("quality", "medium");
    form.append("output_format", "png");
    form.append("input_fidelity", "high");
    form.append("prompt", prompt);

    const customerFile = new File([customerPhotoBuffer], "customer.png", {
      type: "image/png",
    });
    const productFile = new File([productImageBuffer], "product.png", {
      type: "image/png",
    });

    form.append("image[]", customerFile);
    form.append("image[]", productFile);
  } else {
    // Fallback: use form-data package or manual multipart
    throw new Error(
      "FormData is not available. Node.js 18+ is required for this feature."
    );
  }

  const response = await fetch("https://api.openai.com/v1/images/edits", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
    },
    body: form,
  });

  const data = await response.json().catch(() => ({}));

  console.log(
    "[callOpenAIImageEdit] OpenAI Response Status:",
    response.status
  );

  if (!response.ok) {
    console.error("[callOpenAIImageEdit] OpenAI API error:", response.status, data);
    const error = new Error(
      data.error?.message || "AI try-on generation failed"
    );
    error.statusCode = response.status;
    throw error;
  }

  const b64 = data.data?.[0]?.b64_json;
  if (!b64) {
    const error = new Error("AI response did not include a generated image");
    error.statusCode = 502;
    throw error;
  }

  await fs.promises.mkdir(GENERATED_DIR, { recursive: true });

  const filename = `tryon_${Date.now()}_${randomUUID()}.png`;
  const outputPath = path.join(GENERATED_DIR, filename);
  await fs.promises.writeFile(outputPath, Buffer.from(b64, "base64"));

  return `/uploads/tryon/generated/${filename}`;
}

async function generateTryOn(req, res) {
  try {
    const customerId = req.customer.customerId;

    const profileIdRaw = req.body.profileId;
    const productId = Number(req.body.productId);
    const productImageUrl = req.body.productImageUrl;

    const profileId =
      profileIdRaw !== undefined &&
      profileIdRaw !== null &&
      profileIdRaw !== ""
        ? Number(profileIdRaw)
        : null;

    console.log("[generateTryOn] Request received:", {
      customerId,
      profileId,
      productId,
      productImageUrl,
      hasTemporaryPhoto: !!req.file,
      temporaryPhotoName: req.file?.originalname,
    });

    // --------------------------------------------------
    // Validate product
    // --------------------------------------------------

    if (!productId) {
      return res.status(400).json({
        success: false,
        message: "productId is required",
      });
    }

    // --------------------------------------------------
    // Main User OR Additional Try-On Profile
    // --------------------------------------------------

    if (!profileId && !req.file) {
      return res.status(400).json({
        success: false,
        message:
          "Either a try-on profile or a temporary customer photo is required",
      });
    }

    // --------------------------------------------------
    // Load product
    // --------------------------------------------------

    const product =
      await productService.findPublicProductById(productId);

      console.log(
  "[generateTryOn] PRODUCT ID:",
  productId
);

console.log(
  "[generateTryOn] PRODUCT IMAGE URL FROM CLIENT:",
  productImageUrl
);

console.log(
  "[generateTryOn] PRODUCT COLORS:",
  JSON.stringify(
    product?.colors,
    null,
    2
  )
);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    // --------------------------------------------------
    // Customer photo
    // --------------------------------------------------

    let customerPhotoPath;
    let profile = null;

    // ==================================================
    // CASE 1: ADDITIONAL TRY-ON PROFILE
    // ==================================================

    if (profileId) {
      profile =
        await tryonProfileModel.getById(
          profileId,
          customerId
        );

      if (!profile) {
        return res.status(404).json({
          success: false,
          message: "Try-on profile not found",
        });
      }

      if (!profile.photo_url) {
        return res.status(400).json({
          success: false,
          message:
            "Please add a profile photo before generating try-on",
        });
      }

      customerPhotoPath =
        uploadPathToDisk(profile.photo_url);

      console.log(
        "[generateTryOn] Using saved profile photo:",
        customerPhotoPath
      );

      if (
        !customerPhotoPath ||
        !fs.existsSync(customerPhotoPath)
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Saved customer photo file is missing",
        });
      }
    }

    // ==================================================
    // CASE 2: MAIN USER TEMPORARY PHOTO
    // ==================================================

    else {
      if (!req.file || !req.file.buffer) {
        return res.status(400).json({
          success: false,
          message:
            "Temporary customer photo is required",
        });
      }

      // ------------------------------------------------
      // Save temporarily to disk
      // ------------------------------------------------

      const tempDir = path.join(
        UPLOAD_ROOT,
        "tryon",
        "temp"
      );

      await fs.promises.mkdir(tempDir, {
        recursive: true,
      });

      const extension =
        path.extname(
          req.file.originalname || ""
        ).toLowerCase() || ".jpg";

      const filename =
        `temp_${Date.now()}_${randomUUID()}${extension}`;

      customerPhotoPath =
        path.join(tempDir, filename);

      await fs.promises.writeFile(
        customerPhotoPath,
        req.file.buffer
      );

      console.log(
        "[generateTryOn] Temporary Main User photo saved:",
        customerPhotoPath
      );
    }

    // --------------------------------------------------
// Product image
// --------------------------------------------------

console.log(
  "[generateTryOn] productImageUrl received:",
  productImageUrl
);

console.log(
  "[generateTryOn] productId:",
  productId
);

console.log(
  "[generateTryOn] product object:",
  JSON.stringify(
    product,
    null,
    2
  )
);

    const productImagePath =
      pickProductImage(
        product,
        productImageUrl
      );

      console.log(
  "[generateTryOn] Product image path:",
  productImagePath
);

console.log(
  "[generateTryOn] Product image exists:",
  productImagePath
    ? fs.existsSync(productImagePath)
    : false
);

    if (
      !productImagePath ||
      !fs.existsSync(productImagePath)
    ) {
      return res.status(400).json({
        success: false,
        message:
          "Selected product image file is missing",
      });
    }

    // --------------------------------------------------
    // Generate AI image
    // --------------------------------------------------

    console.log(
      "[generateTryOn] Calling OpenAI API..."
    );

    const generatedImageUrl =
      await callOpenAIImageEdit({
        customerPhotoPath,
        productImagePath,
        product,
        profile,
      });

    console.log(
      "[generateTryOn] Success:",
      {
        generatedImageUrl,
      }
    );

    // --------------------------------------------------
    // Delete Main User temporary photo
    // --------------------------------------------------

    if (!profileId && customerPhotoPath) {
      try {
        await fs.promises.unlink(
          customerPhotoPath
        );

        console.log(
          "[generateTryOn] Temporary photo deleted"
        );
      } catch (cleanupError) {
        console.warn(
          "[generateTryOn] Failed to delete temporary photo:",
          cleanupError.message
        );
      }
    }

    // --------------------------------------------------
    // Response
    // --------------------------------------------------

    return res.json({
      success: true,
      data: {
        generatedImageUrl,
      },
    });

  } catch (err) {
    console.error(
      "[generateTryOn] Error:",
      err
    );

    return res.status(
      err.statusCode || 500
    ).json({
      success: false,
      message:
        err.message ||
        "Failed to generate try-on",
    });
  }
}

module.exports = {
  generateTryOn,
};
