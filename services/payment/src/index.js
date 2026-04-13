const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'payment' });
});

const PORT = process.env.PORT || 3003;
app.listen(PORT, () => {
  console.log(`payment service is running on port ${PORT}`);
});