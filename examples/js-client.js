#!/usr/bin/env node
/**
 * JavaScript client that expects data via SOAP-like format
 * This client cannot directly talk to the Python REST service
 * Jolie will act as the bridge
 */

const http = require('http');

function getUserInfo(userId) {
    // This client expects to communicate via SODEP protocol on port 8000
    // where Jolie mediator is listening
    const options = {
        hostname: 'localhost',
        port: 8000,
        path: `/getUser?id=${userId}`,
        method: 'GET'
    };

    const req = http.request(options, (res) => {
        let data = '';

        res.on('data', (chunk) => {
            data += chunk;
        });

        res.on('end', () => {
            console.log('Received from Jolie mediator:');
            console.log(JSON.parse(data));
        });
    });

    req.on('error', (error) => {
        console.error('Error:', error);
    });

    req.end();
}

// Request user with ID 1
console.log('JavaScript client requesting user info...');
getUserInfo(1);
