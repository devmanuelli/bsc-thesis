#!/usr/bin/env python3
"""
Service A: Provides employee data via HTTP REST with JSON format
Could be written in any language - we use Python + Flask for simplicity
"""

from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/employee', methods=['GET'])
def get_employee():
    emp_id = request.args.get('id', '1')

    # Return data in JSON format
    employee = {"name": "Alice"}

    print(f"[JSON Service] Responded with employee {emp_id} in JSON format")
    return jsonify(employee)

if __name__ == '__main__':
    print("=" * 50)
    print("Service A: REST API with JSON")
    print("Running on http://localhost:8001")
    print("Protocol: HTTP + JSON")
    print("=" * 50)
    app.run(port=8001, debug=False)
