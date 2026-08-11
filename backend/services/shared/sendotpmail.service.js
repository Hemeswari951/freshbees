const transporter = require('../../config/mailer');

/**
 * Standard Professional OTP Mail Service for THIRAA
 * Configured for maximum Inbox delivery rates
 */
async function sendOtpMail({ toEmail, otp, purpose }) {
  let purposeHeading = 'Verify Your Account';
  
  if (purpose === 'password_reset' || purpose === 'forgot_password') {
    purposeHeading = 'Reset Your Password';
  } else if (purpose === 'login' || purpose === 'auth') {
    purposeHeading = 'Verify Your Login';
  } else if (purpose === 'registration') {
    purposeHeading = 'Welcome to THIRAA';
  }

  const logoUrl = ''; 

  const mailOptions = {
    // 1. Clean Sender Name
    from: `"THIRAA" <${process.env.MAIL_USER}>`,
    to: toEmail,
    
    // 2. Short & Safe Subject Line (Avoids Spam Filters)
    subject: `THIRAA OTP: ${otp}`,

    // 3. Plain Text Fallback (Prevents Gmail Spam Detection)
    text: `Your THIRAA OTP code is: ${otp}. Valid for 2 minutes. Do not share this code with anyone.`,

    // 4. Clean HTML Design
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            @import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@600;700;800&family=Montserrat:wght@400;500;600;700&display=swap');
          </style>
        </head>
        <body style="margin:0; padding:40px 10px; background-color:#FAF8F5; font-family:'Montserrat', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
          <table width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td align="center">
                <table width="100%" style="max-width:460px; background-color:#FFFDF9; border-radius:24px; overflow:hidden; border:1px solid #E8DFD1; box-shadow: 0 15px 35px rgba(184, 150, 92, 0.12);" border="0" cellspacing="0" cellpadding="0">
                  
                  <!-- Header -->
                  <tr>
                    <td style="padding:40px 30px 20px 30px; text-align:center; background: linear-gradient(180deg, #FAF4EB 0%, #FFFDF9 100%);">
                      ${logoUrl ? `
                        <img src="${logoUrl}" alt="THIRAA Logo" style="max-width:70px; height:auto; margin-bottom:12px;" />
                      ` : `
                        <div style="display:inline-block; width:58px; height:58px; border:1.5px solid #C5A059; border-radius:50%; text-align:center; line-height:56px; margin-bottom:14px; background-color:#FFFDF9; box-shadow: 0 4px 12px rgba(197, 160, 89, 0.15);">
                          <span style="font-family:'Cinzel', serif; font-size:28px; font-weight:700; color:#C5A059; display:inline-block; margin-top:1px;">T</span>
                        </div>
                      `}
                      <h1 style="margin:0; color:#2B2319; font-family:'Cinzel', serif; font-size:26px; font-weight:700; letter-spacing:4px; text-transform:uppercase;">
                        THIRAA
                      </h1>
                      <p style="margin:6px 0 0 0; color:#9E8A70; font-size:10px; font-weight:600; letter-spacing:2px; text-transform:uppercase;">
                        Virtual Trials, Real You
                      </p>
                    </td>
                  </tr>

                  <!-- Main Content -->
                  <tr>
                    <td style="padding:20px 36px 36px 36px; text-align:center;">
                      <h2 style="margin:0 0 10px 0; color:#2B2319; font-size:20px; font-weight:700;">
                        ${purposeHeading}
                      </h2>
                      <p style="margin:0 0 28px 0; color:#6B5E50; font-size:13px; line-height:1.6;">
                        Hello! Use the security code below to complete your access. Valid for <strong>2 minutes</strong>.
                      </p>

                      <!-- OTP Box -->
                      <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom:24px;">
                        <tr>
                          <td align="center" style="background-color:#FFFDF9; border:2px solid #C5A059; border-radius:16px; padding:22px; box-shadow: inset 0 0 12px rgba(197, 160, 89, 0.08);">
                            <span style="font-family:'Cinzel', serif, monospace; font-size:38px; font-weight:800; color:#1A1510; letter-spacing:10px; display:inline-block; margin-left:10px;">
                              ${otp}
                            </span>
                          </td>
                        </tr>
                      </table>

                      <!-- Security Tip -->
                      <div style="background-color:#F5EFE6; border-radius:12px; padding:12px 16px; text-align:center;">
                        <p style="margin:0; color:#705C45; font-size:11px; font-weight:500; line-height:1.4;">
                          🔒 <strong>Security Tip:</strong> Staff never ask for OTP. Keep it secure.
                        </p>
                      </div>
                    </td>
                  </tr>

                  <!-- Footer -->
                  <tr>
                    <td style="background-color:#FAF4EB; padding:20px 30px; border-top:1px solid #E8DFD1; text-align:center;">
                      <p style="margin:0; color:#9E8A70; font-size:11px; line-height:1.5;">
                        Sent by THIRAA.<br>Ignore if not requested.
                      </p>
                    </td>
                  </tr>

                </table>
              </td>
            </tr>
          </table>
        </body>
      </html>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[EMAIL DELIVERED] Sent to: ${toEmail} | Message ID: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error(`[EMAIL ERROR] Failed to send email to ${toEmail}:`, error);
    throw error;
  }
}

module.exports = { sendOtpMail };