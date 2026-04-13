const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');

const app = express();
app.use(cors());
// Note: http-proxy-middleware typically needs raw requests for some REST methods unless configured parsing
app.use(express.json()); 

const JWT_SECRET = process.env.JWT_SECRET || 'secret';

// Auth Middleware Verification
const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader) {
    const token = authHeader.split(' ')[1];
    jwt.verify(token, JWT_SECRET, (err, user) => {
      if (err) return res.sendStatus(403);
      req.user = user;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};

// Route services dynamically based on ENV URLs
const services = [
  { p: '/api/auth', target: process.env.AUTH_SERVICE_URL || 'http://localhost:3001' },
  { p: '/api/profile', target: process.env.PROFILE_SERVICE_URL || 'http://localhost:3002', protected: true },
  { p: '/api/payment', target: process.env.PAYMENT_SERVICE_URL || 'http://localhost:3003', protected: true },
  { p: '/api/notification', target: process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:3004', protected: true },
  { p: '/api/storage', target: process.env.STORAGE_SERVICE_URL || 'http://localhost:3005', protected: true }
];

services.forEach(({ p, target, protected }) => {
  const proxyOptions = {
    target,
    changeOrigin: true,
    pathRewrite: { [`^${p}`]: '' },
  };
  
  if (protected) {
    app.use(p, verifyToken, createProxyMiddleware(proxyOptions));
  } else {
    app.use(p, createProxyMiddleware(proxyOptions));
  }
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'gateway' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Gateway service proxying traffic on port ${PORT}`);
});