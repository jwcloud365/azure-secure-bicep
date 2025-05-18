// Simple health check API endpoint
module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');
    
    context.res = {
        status: 200,
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            status: 'healthy',
            environment: process.env.WEBSITE_SITE_NAME || 'unknown',
            timestamp: new Date().toISOString(),
            version: '1.0.0'
        })
    };
};
