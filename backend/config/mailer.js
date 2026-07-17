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