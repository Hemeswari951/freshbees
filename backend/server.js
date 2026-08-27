require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const app     = express();
const path    = require('path');
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/admin',    require('./routes/admin/index'));
app.use('/api/shop-owner',     require('./routes/shop_owner/index'));
app.use('/api/customer', require('./routes/customer/index'));

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});