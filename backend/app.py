from flask import Flask, request, jsonify
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app) # Enable CORS for frontend communication

@app.route('/api/submit', methods=['POST'])
def submit_form():
    data = request.json
    name = data.get('name')
    email = data.get('email')

    if not name or not email:
        return jsonify({"message": "Name and email are required!"}), 400

    # In a real app, you would save this to a database.
    print(f"Received submission: Name={name}, Email={email}")
    return jsonify({"message": f"Form submitted successfully for {name}!"}), 200

@app.route('/')
def health():
     return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

