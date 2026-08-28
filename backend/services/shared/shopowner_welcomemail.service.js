const transporter = require('../../config/mailer');

async function sendShopOwnerWelcomeMail({ ownerName, ownerEmail, shopName, rawPassword }) {
  await transporter.sendMail({
    from:    `"THIRAA Admin" <${process.env.MAIL_USER}>`,
    to:      ownerEmail,
    subject: `Welcome to THIRAA — Login credentials for "${shopName}"`,
    html: `
      <!DOCTYPE html>
      <html>
        <body style="margin:0;padding:0;background:#F5F5F5;font-family:Arial,sans-serif;">
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td align="center" style="padding:40px 0;">
                <table width="520" cellpadding="0" cellspacing="0"
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
                      <p style="margin:0 0 6px;color:#555;font-size:13px;">
                        Hello ${ownerName},
                      </p>
                      <h2 style="margin:0 0 16px;color:#111;font-size:18px;">
                        Your shop is ready on THIRAA 🎉
                      </h2>
                      <p style="color:#555;font-size:13px;line-height:1.7;margin:0 0 24px;">
                        Your shop <strong style="color:#111;">"${shopName}"</strong>
                        has been created. Use the temporary credentials below to log in.
                      </p>

                      <!-- Credentials -->
                      <table width="100%" cellpadding="0" cellspacing="0"
                        style="background:#F9F5F0;border-radius:8px;
                               border:1px solid #E8E0D8;margin-bottom:20px;">
                        <tr>
                          <td style="padding:20px 24px;">
                            <p style="margin:0 0 14px;font-size:11px;color:#999;
                                      text-transform:uppercase;letter-spacing:1px;">
                              Temporary Login Credentials
                            </p>
                            <table cellpadding="0" cellspacing="0">
                              <tr>
                                <td style="padding:6px 0;font-size:13px;
                                           color:#777;width:110px;">Email</td>
                                <td style="padding:6px 0;font-size:13px;
                                           font-weight:bold;color:#111;">
                                  ${ownerEmail}
                                </td>
                              </tr>
                              <tr>
                                <td style="padding:6px 0;font-size:13px;color:#777;">
                                  Password
                                </td>
                                <td style="padding:6px 0;font-size:18px;
                                           font-weight:bold;color:#111;letter-spacing:3px;">
                                  ${rawPassword}
                                </td>
                              </tr>
                            </table>
                          </td>
                        </tr>
                      </table>

                      <!-- Warning -->
                      <table width="100%" cellpadding="0" cellspacing="0"
                        style="background:#FFF8E8;border-radius:8px;
                               border:1px solid #F0D890;margin-bottom:28px;">
                        <tr>
                          <td style="padding:14px 20px;">
                            <p style="margin:0;font-size:12px;color:#7A5C00;line-height:1.6;">
                              ⚠️ This is a <strong>temporary password</strong>.
                              You will be asked to create a new password
                              when you log in for the first time.
                            </p>
                          </td>
                        </tr>
                      </table>

                      <!-- CTA -->
                      <table cellpadding="0" cellspacing="0">
                        <tr>
                          <td style="background:#111;border-radius:8px;">
                            <a href="${process.env.SHOP_APP_URL || '#'}"
                              style="display:inline-block;padding:13px 30px;
                                     color:#fff;font-size:13px;
                                     font-weight:bold;text-decoration:none;">
                              Open Shop Dashboard →
                            </a>
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
                        Sent by THIRAA Admin. Questions? Contact
                        <a href="mailto:${process.env.MAIL_USER}"
                           style="color:#111;">${process.env.MAIL_USER}</a>.
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

module.exports = { sendShopOwnerWelcomeMail };