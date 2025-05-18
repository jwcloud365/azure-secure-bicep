// Simple Express server for App Service
const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

// Serve static files
app.use(express.static('.'));

// Health endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    environment: process.env.WEBSITE_SITE_NAME || 'unknown',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Default route
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/test.html');
});

// Start the server
app.listen(port, () => {
  console.log(`App listening at port ${port}`);
});
