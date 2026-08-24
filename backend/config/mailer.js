const nodemailer = require('nodemailer');
console.log(process.env.MAIL_USER);
console.log(process.env.MAIL_PASS);
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,   // Gmail App Password (not your login password)
  },
});

module.exports = transporter;



// /* Brevo connection */

// const PROVIDER = process.env.EMAIL_PROVIDER || 'brevo';

// let transporter;

// if (PROVIDER === 'smtp') {
//   // ---------- SMTP (Gmail) — only works on a PAID Render instance ----------
//   const nodemailer = require('nodemailer');

//   transporter = nodemailer.createTransport({
//     host: 'smtp.gmail.com',
//     port: 465,
//     secure: true,
//     auth: {
//       user: process.env.MAIL_USER,
//       pass: process.env.MAIL_PASS,
//     },
//     family: 4, // force IPv4 - fixes Render's IPv6 ENETUNREACH timeout
//   });

// } else {
//   // ---------- Brevo (HTTPS API) — works on Render free tier, no domain required ----------
//   transporter = {
//     async sendMail({ to, subject, html }) {
//       const safeFrom = process.env.MAIL_FROM || 'no-reply@thiraa.com';

//       const response = await fetch('https://api.brevo.com/v3/smtp/email', {
//         method: 'POST',
//         headers: {
//           'Content-Type': 'application/json',
//           'api-key': process.env.BREVO_API_KEY,
//         },
//         body: JSON.stringify({
//           sender: { email: safeFrom, name: 'THIRAA' },
//           to: [{ email: to }],
//           subject,
//           htmlContent: html,
//         }),
//       });

//       const data = await response.json();

//       if (!response.ok) {
//         throw new Error(`Brevo error: ${data.message || JSON.stringify(data)}`);
//       }

//       return data;
//     },
//   };
// }

// module.exports = transporter;