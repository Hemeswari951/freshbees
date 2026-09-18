const pool = require('../../config/db');

const TryOnProfile = {

  // ============================================================
  // GET ALL PROFILES FOR CUSTOMER
  // ============================================================

  async getByCustomerId(customerId) {
  const result = await pool.query(
    `
    SELECT
      tp.profile_id,
      tp.customer_id,
      tp.profile_name,
      tp.relationship,
      tp.gender,
      tp.age,
      TO_CHAR(tp.date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
      tp.size,
      tp.height,
      tp.weight,
      tp.photo_url,
      tp.is_default,
      tp.created_at,
      tp.updated_at,

      tps.style_id,
      tps.apparel_size AS style_apparel_size,
      tps.fit_preference AS style_fit_preference,
      tps.preferred_colors AS style_preferred_colors,
      tps.preferred_styles AS style_preferred_styles

    FROM tryon_profiles tp

    LEFT JOIN tryon_profile_styles tps
      ON tp.profile_id = tps.profile_id

    WHERE tp.customer_id = $1

    ORDER BY
      tp.is_default DESC,
      tp.created_at ASC
    `,
    [customerId]
  );

  return result.rows;
},

  // ============================================================
  // GET ONE PROFILE
  // ============================================================

  async getById(profileId, customerId) {
  const result = await pool.query(
    `
    SELECT
      tp.profile_id,
      tp.customer_id,
      tp.profile_name,
      tp.relationship,
      tp.gender,
      tp.age,
      TO_CHAR(tp.date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
      tp.size,
      tp.height,
      tp.weight,
      tp.photo_url,
      tp.is_default,
      tp.created_at,
      tp.updated_at,

      tps.style_id,
      tps.apparel_size AS style_apparel_size,
      tps.fit_preference AS style_fit_preference,
      tps.preferred_colors AS style_preferred_colors,
      tps.preferred_styles AS style_preferred_styles

    FROM tryon_profiles tp

    LEFT JOIN tryon_profile_styles tps
      ON tp.profile_id = tps.profile_id

    WHERE tp.profile_id = $1
      AND tp.customer_id = $2
    `,
    [profileId, customerId]
  );

  return result.rows[0] || null;
},
  // ============================================================
  // CREATE PROFILE
  // ============================================================

  async create({
    customerId,
    profileName,
    relationship,
    gender,
    age,
    dateOfBirth,
    size,
    height,
    weight,
    photoUrl,
    isDefault = false,
  }) {

    const result = await pool.query(
      `
      INSERT INTO tryon_profiles (
        customer_id,
        profile_name,
        relationship,
        gender,
        age,
        date_of_birth,
        size,
        height,
        weight,
        photo_url,
        is_default
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, $8, $9, $10, $11
      )
     RETURNING
      profile_id,
      customer_id,
      profile_name,
      relationship,
      gender,
      age,
      TO_CHAR(date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
      size,
      height,
      weight,
      photo_url,
      is_default,
      created_at,
      updated_at
    `,
      [
        customerId,
        profileName,
        relationship,
        gender || null,
        age || null,
        dateOfBirth || null,
        size || null,
        height || null,
        weight || null,
        photoUrl || null,
        isDefault,
      ]
    );

    return result.rows[0];
  },


  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  async update(profileId, customerId, data) {

    const result = await pool.query(
      `
      UPDATE tryon_profiles
      SET
        profile_name = COALESCE($3, profile_name),
        relationship = COALESCE($4, relationship),
        gender = COALESCE($5, gender),
        age = COALESCE($6, age),
        date_of_birth = COALESCE($7, date_of_birth),
        size = COALESCE($8, size),
        height = COALESCE($9, height),
        weight = COALESCE($10, weight),
        photo_url = COALESCE($11, photo_url),
        updated_at = CURRENT_TIMESTAMP
      WHERE profile_id = $1
        AND customer_id = $2
      RETURNING
      profile_id,
      customer_id,
      profile_name,
      relationship,
      gender,
      age,
      TO_CHAR(date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
      size,
      height,
      weight,
      photo_url,
      is_default,
      created_at,
      updated_at
    `,
      [
        profileId,
        customerId,
        data.profileName,
        data.relationship,
        data.gender,
        data.age,
        data.dateOfBirth,
        data.size,
        data.height,
        data.weight,
        data.photoUrl,
      ]
    );

    console.log("TRYON UPDATE DB RESULT:", result.rows[0]);

    return result.rows[0] || null;
  },


  // ============================================================
  // DELETE PROFILE
  // ============================================================

  async delete(profileId, customerId) {

    const result = await pool.query(
      `
      DELETE FROM tryon_profiles
      WHERE profile_id = $1
        AND customer_id = $2
      RETURNING profile_id
      `,
      [profileId, customerId]
    );

    return result.rows[0] || null;
  },
  // ============================================================
// GET MAIN USER PROFILE
// ============================================================

async getMainProfile(customerId) {
  const result = await pool.query(
    `
    SELECT
      tp.profile_id,
      tp.customer_id,
      tp.profile_name,
      tp.relationship,
      tp.gender,
      tp.age,
      TO_CHAR(tp.date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
      tp.size,
      tp.height,
      tp.weight,
      tp.photo_url,
      tp.is_default,
      tp.created_at,
      tp.updated_at,

      tps.style_id,
      tps.apparel_size AS style_apparel_size,
      tps.fit_preference AS style_fit_preference,
      tps.preferred_colors AS style_preferred_colors,
      tps.preferred_styles AS style_preferred_styles

    FROM tryon_profiles tp

    LEFT JOIN tryon_profile_styles tps
      ON tp.profile_id = tps.profile_id

    WHERE tp.customer_id = $1
  AND LOWER(tp.relationship) = 'self'

LIMIT 1
    `,
    [customerId]
  );

  return result.rows[0] || null;
},

};



module.exports = TryOnProfile;