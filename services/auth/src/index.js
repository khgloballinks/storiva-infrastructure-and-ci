const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth.routes');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'auth' });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`auth service is running on port ${PORT}`);
});