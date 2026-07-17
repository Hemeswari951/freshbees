const transporter = require('../../config/mailer');

async function sendOtpMail({ toEmail, otp, purpose }) {
  const purposeText = purpose === 'password_reset' 
    ? 'Reset Your Password' 
    : 'Verify Your Login';

  await transporter.sendMail({
    from: `"THIRAA" <${process.env.MAIL_USER}>`,
    to: toEmail,
    subject: `THIRAA - Your OTP Code`,
    html: `
      <!DOCTYPE html>
      <html>
        <body style="margin:0;padding:0;background:#F5F5F5;font-family:Arial,sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td align="center" style="padding:40px 0;">
                <table width="480" cellpadding="0" cellspacing="0"
                  style="background:#fff;border-radius:12px;overflow:hidden;
                         border:1px solid #E8E0D8;">

                  <!-- Header -->
                  <tr>
                    <td style="background:#111;padding:28px 36px;">
                      <h1 style="margin:0;color:#fff;font-size:22px;letter-spacing:2px;">
                        THIRAA
                      </h1>
                      <p style="margin:4px 0 0;color:#aaa;font-size:12px;">
                        Fashion & Beauty Marketplace
                      </p>
                    </td>
                  </tr>

                  <!-- Body -->
                  <tr>
                    <td style="padding:32px 36px;">
                      <h2 style="margin:0 0 16px;color:#111;font-size:18px;">
                        ${purposeText}
                      </h2>
                      <p style="color:#555;font-size:13px;line-height:1.7;margin:0 0 24px;">
                        Use the OTP below to proceed. This code is valid for
                        <strong style="color:#111;">2 minutes</strong>.
                      </p>

                      <!-- OTP Box -->
                      <table width="100%" cellpadding="0" cellspacing="0"
                        style="background:#F9F5F0;border-radius:8px;
                               border:1px solid #E8E0D8;margin-bottom:20px;">
                        <tr>
                          <td align="center" style="padding:24px;">
                            <p style="margin:0 0 10px;font-size:11px;color:#999;
                                      text-transform:uppercase;letter-spacing:1px;">
                              Your OTP
                            </p>
                            <p style="margin:0;font-size:32px;font-weight:bold;
                                      color:#111;letter-spacing:8px;">
                              ${otp}
                            </p>
                          </td>
                        </tr>
                      </table>

                      <!-- Warning -->
                      <table width="100%" cellpadding="0" cellspacing="0"
                        style="background:#FFF8E8;border-radius:8px;
                               border:1px solid #F0D890;">
                        <tr>
                          <td style="padding:14px 20px;">
                            <p style="margin:0;font-size:12px;color:#7A5C00;line-height:1.6;">
                              ⚠️ Do not share this OTP with anyone. THIRAA
                              staff will never ask for your OTP.
                            </p>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </tr>

                  <!-- Footer -->
                  <tr>
                    <td style="background:#F9F5F0;padding:20px 36px;
                               border-top:1px solid #E8E0D8;">
                      <p style="margin:0;font-size:11px;color:#aaa;line-height:1.6;">
                        Sent by THIRAA. Didn't request this? Ignore this email.
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
  });
}

module.exports = { sendOtpMail };