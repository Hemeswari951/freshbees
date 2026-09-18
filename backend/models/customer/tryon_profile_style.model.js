const pool = require("../../config/db");

const TryOnProfileStyle = {

  // =====================================================
  // GET STYLE PREFERENCES FOR ONE TRY-ON PROFILE
  // =====================================================

  async getByProfileId(profileId, customerId) {
    const result = await pool.query(
      `
      SELECT
        s.profile_id,
        s.apparel_size,
        s.fit_preference,
        s.preferred_colors,
        s.preferred_styles,
        s.created_at,
        s.updated_at
      FROM tryon_profile_styles s
      INNER JOIN tryon_profiles p
        ON p.profile_id = s.profile_id
      WHERE s.profile_id = $1
        AND p.customer_id = $2
      LIMIT 1
      `,
      [profileId, customerId]
    );

    return result.rows[0] || null;
  },


  // =====================================================
  // CREATE OR UPDATE STYLE PREFERENCES
  // =====================================================

  async save(
    
    profileId,
    customerId,
    
    {
      apparelSize,
      fitPreference,
      preferredColors,
      preferredStyles,
    }
    
  ) 
  
  {

    // First make sure this Try-On Profile
    // belongs to the logged-in customer.
    const profileCheck = await pool.query(
      `
      SELECT profile_id
      FROM tryon_profiles
      WHERE profile_id = $1
        AND customer_id = $2
      LIMIT 1
      `,
      [profileId, customerId]
    );
    console.log(
  "Profile check result:",
  profileCheck.rows
);

    if (profileCheck.rows.length === 0) {
      return null;
    }

    const result = await pool.query(
      `
      INSERT INTO tryon_profile_styles (
        profile_id,
        apparel_size,
        fit_preference,
        preferred_colors,
        preferred_styles,
        created_at,
        updated_at
      )
      VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      )

      ON CONFLICT (profile_id)
      DO UPDATE SET
        apparel_size = EXCLUDED.apparel_size,
        fit_preference = EXCLUDED.fit_preference,
        preferred_colors = EXCLUDED.preferred_colors,
        preferred_styles = EXCLUDED.preferred_styles,
        updated_at = CURRENT_TIMESTAMP

      RETURNING
        profile_id,
        apparel_size,
        fit_preference,
        preferred_colors,
        preferred_styles,
        created_at,
        updated_at
      `,
      [
        profileId,
        apparelSize || null,
        fitPreference || null,
        preferredColors || [],
        preferredStyles || [],
      ]
    );

    return result.rows[0];
  },
};

module.exports = TryOnProfileStyle;