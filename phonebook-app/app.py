from flask import Flask, request, jsonify, render_template
from flask_pymongo import PyMongo
import logging
import prometheus_client
from prometheus_client import Counter, Histogram
import time
import os
import json
from dotenv import load_dotenv
from bson.json_util import dumps
from bson.objectid import ObjectId


load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configure MongoDB
app.config["MONGO_URI"] = os.getenv("MONGO_URI")
if not app.config["MONGO_URI"]:
    raise ValueError("No MONGO_URI environment variable set")

mongo = PyMongo(app)

# Prometheus metrics
REQUESTS = Counter(
    'phonebook_requests_total',
    'Total number of requests to the phonebook service',
    ['method', 'endpoint']
)
RESPONSE_TIME = Histogram(
    'notes_response_time_seconds',
    'Response time in seconds',
    ['method', 'endpoint']
)

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    duration = (time.time() - request.start_time) * 1000  # Duration in milliseconds
    
    if request.path != '/metrics':
        # Increment Prometheus metrics
        REQUESTS.labels(
            method=request.method,
            endpoint=request.path
        ).inc()
        RESPONSE_TIME.labels(
            method=request.method,
            endpoint=request.path
        ).observe(time.time() - request.start_time)
        
        # Log as a JSON object
        log_data = {
            "timestamp": time.strftime('%Y-%m-%d %H:%M:%S'),
            "level": "INFO",
            "logger": "flask",
            "method": request.method,
            "endpoint": request.path,
            "status_code": response.status_code,
            "duration_ms": duration,
            "user_agent": request.headers.get("User-Agent"),
            "ip": request.remote_addr
        }
        logger.info(json.dumps(log_data))


    return response


@app.route('/')
def home():
    logger.info("Accessing home page")
    return render_template('index.html')

@app.route('/contacts', methods=['GET'])
def get_contacts():
    logger.info("Retrieving all contacts")
    contacts = mongo.db.contacts.find()
    return dumps(contacts)

@app.route('/contacts/<id>', methods=['GET'])
def get_contact(id):
    logger.info(f"Retrieving contact with ID: {id}")
    contact = mongo.db.contacts.find_one({'_id': ObjectId(id)})
    if contact:
        return dumps(contact)
    return jsonify({'error': 'Contact not found'}), 404

@app.route('/contacts', methods=['POST'])
def create_contact():
    logger.info("Creating new contact")
    data = request.get_json()
    logger.info(f"Received data: {data}")
    
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    contact = {
        'name': data.get('name'),
        'phone': data.get('phone'),
        'email': data.get('email'),
        'notes': data.get('notes', ''),
        'created_at': time.strftime('%Y-%m-%d %H:%M:%S')
    }
    
    try:
        logger.info("Attempting to insert contact into MongoDB")
        result = mongo.db.contacts.insert_one(contact)
        contact['_id'] = result.inserted_id
        return dumps(contact), 201
    except Exception as e:
        logger.error(f"Error creating contact: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/contacts/<id>', methods=['PUT'])
def update_contact(id):
    logger.info(f"Updating contact with ID: {id}")
    data = request.get_json()
    logger.info(f"Update data received: {data}")
    
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    # Only update the fields that are provided
    update_fields = {}
    for field in ['name', 'phone', 'email', 'notes']:
        if field in data:
            update_fields[field] = data[field]
    
    logger.info(f"Fields to update: {update_fields}")  # Debug log
    
    if not update_fields:
        return jsonify({'error': 'No fields to update'}), 400
    
    try:
        result = mongo.db.contacts.update_one(
            {'_id': ObjectId(id)},
            {'$set': update_fields}
        )
        if result.matched_count:
            return jsonify({'message': 'Contact updated successfully'})
        return jsonify({'error': 'Contact not found'}), 404
    except Exception as e:
        logger.error(f"Error updating contact: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/contacts/<id>', methods=['DELETE'])
def delete_contact(id):
    logger.info(f"Deleting contact with ID: {id}")
    result = mongo.db.contacts.delete_one({'_id': ObjectId(id)})
    if result.deleted_count:
        return jsonify({'message': 'Contact deleted successfully'})
    return jsonify({'error': 'Contact not found'}), 404

@app.route('/metrics')
def metrics():
    logger.info("Accessing metrics endpoint")
    return prometheus_client.generate_latest()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)