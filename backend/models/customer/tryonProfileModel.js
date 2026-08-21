const pool = require('../../config/db');

const TryOnProfile = {

  // Get all profiles belonging to a customer
  async getByCustomerId(customerId) {
    const result = await pool.query(
      `
      SELECT
        profile_id,
        customer_id,
        profile_name,
        relationship,
        gender,
        age,
        size,
        height,
        weight,
        photo_url,
        is_default,
        created_at,
        updated_at
      FROM tryon_profiles
      WHERE customer_id = $1
      ORDER BY is_default DESC, created_at ASC
      `,
      [customerId]
    );

    return result.rows;
  },

  // Get one profile
  async getById(profileId, customerId) {
    const result = await pool.query(
      `
      SELECT
        profile_id,
        customer_id,
        profile_name,
        relationship,
        gender,
        age,
        size,
        height,
        weight,
        photo_url,
        is_default,
        created_at,
        updated_at
      FROM tryon_profiles
      WHERE profile_id = $1
        AND customer_id = $2
      `,
      [profileId, customerId]
    );

    return result.rows[0] || null;
  },

  // Create a new profile
  async create({
    customerId,
    profileName,
    relationship,
    gender,
    age,
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
        size,
        height,
        weight,
        photo_url,
        is_default
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, $8, $9, $10
      )
      RETURNING *
      `,
      [
        customerId,
        profileName,
        relationship,
        gender || null,
        age || null,
        size || null,
        height || null,
        weight || null,
        photoUrl || null,
        isDefault,
      ]
    );

    return result.rows[0];
  },

  // Update a profile
  async update(profileId, customerId, data) {

    const result = await pool.query(
      `
      UPDATE tryon_profiles
      SET
        profile_name = COALESCE($3, profile_name),
        relationship = COALESCE($4, relationship),
        gender = COALESCE($5, gender),
        age = COALESCE($6, age),
        size = COALESCE($7, size),
        height = COALESCE($8, height),
        weight = COALESCE($9, weight),
        photo_url = COALESCE($10, photo_url),
        updated_at = CURRENT_TIMESTAMP
      WHERE profile_id = $1
        AND customer_id = $2
      RETURNING *
      `,
      [
        profileId,
        customerId,
        data.profileName,
        data.relationship,
        data.gender,
        data.age,
        data.size,
        data.height,
        data.weight,
        data.photoUrl,
      ]
    );

    return result.rows[0] || null;
  },

  // Delete a profile
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
};

module.exports = TryOnProfile;