#!/usr/bin/env python3
"""
Service B: Provides payroll data via HTTP with XML format
Could be written in any language - we use Python + Flask for simplicity
The KEY is the protocol/format (XML), not the language!
"""

from flask import Flask, request, Response
import xml.etree.ElementTree as ET

app = Flask(__name__)

@app.route('/payroll', methods=['GET'])
def get_payroll():
    emp_id = request.args.get('id', '1')

    # Build XML using ElementTree
    root = ET.Element('root')
    ET.SubElement(root, 'salary').text = '5000'

    xml_response = ET.tostring(root, encoding='unicode', method='xml')

    print(f"[XML Service] Responded with payroll for employee {emp_id} in XML format")
    return Response(xml_response, mimetype='application/xml')

if __name__ == '__main__':
    print("=" * 50)
    print("Service B: API with XML")
    print("Running on http://localhost:8002")
    print("Protocol: HTTP + XML")
    print("=" * 50)
    app.run(port=8002, debug=False)
