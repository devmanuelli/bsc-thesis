#!/usr/bin/env python3
"""
Python service that provides user data via HTTP/JSON
This service uses Flask to expose a REST API
"""

from flask import Flask, jsonify
import json

app = Flask(__name__)

users = [
    {"id": 1, "name": "Alice", "email": "alice@example.com"},
    {"id": 2, "name": "Bob", "email": "bob@example.com"}
]

@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    """Get user by ID - returns JSON"""
    user = next((u for u in users if u['id'] == user_id), None)
    if user:
        return jsonify(user)
    return jsonify({"error": "User not found"}), 404

if __name__ == '__main__':
    print("Python service running on http://localhost:5000")
    app.run(port=5000, debug=True)
