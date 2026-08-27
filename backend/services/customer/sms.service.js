const https = require('https');

async function sendOtpSms({ phoneNumber, otp }) {
  const apiKey = process.env.TWO_FACTOR_API_KEY;

  if (!apiKey) {
    throw new Error('TWO_FACTOR_API_KEY is not configured');
  }

  // Your UI sends 10 digits:
  // 8248903089
  //
  // 2Factor requires international format:
  // +918248903089

  let phone = phoneNumber
    .toString()
    .replace(/\D/g, '');

  // Keep only the last 10 digits
  phone = phone.slice(-10);

  if (phone.length !== 10) {
    throw new Error(
      `Invalid Indian mobile number: ${phoneNumber}`
    );
  }

  // Add India country code
  const internationalPhone = `+91${phone}`;

  const templateName = 'OTP1';

  const url =
    `https://2factor.in/API/V1/${encodeURIComponent(apiKey)}` +
    `/SMS/${encodeURIComponent(internationalPhone)}` +
    `/${encodeURIComponent(otp)}` +
    `/${encodeURIComponent(templateName)}`;

  console.log(
    `[SMS] Sending OTP to ${internationalPhone}`
  );

  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        let data = '';

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          console.log(
            `[SMS] 2Factor status: ${res.statusCode}`
          );

          console.log(
            `[SMS] 2Factor response: ${data}`
          );

          if (res.statusCode >= 200 && res.statusCode < 300) {
            try {
              const response = JSON.parse(data);

              if (
                response.Status &&
                response.Status.toLowerCase() === 'success'
              ) {
                return resolve(response);
              }

              return reject(
                new Error(
                  response.Details ||
                  response.message ||
                  '2Factor SMS failed'
                )
              );
            } catch (error) {
              return reject(
                new Error(
                  `Invalid response from 2Factor: ${data}`
                )
              );
            }
          }

          reject(
            new Error(
              `2Factor HTTP ${res.statusCode}: ${data}`
            )
          );
        });
      })
      .on('error', (error) => {
        console.error('[SMS ERROR]', error);
        reject(error);
      });
  });
}

module.exports = {
  sendOtpSms,
};