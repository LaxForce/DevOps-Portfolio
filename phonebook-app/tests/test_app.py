import pytest
from app import app
from unittest.mock import patch, MagicMock
from bson.objectid import ObjectId

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@pytest.fixture
def mock_mongo():
    with patch('app.mongo') as mock_mongo:
        mock_db = MagicMock()
        mock_mongo.db = mock_db
        mock_mongo.db.contacts = MagicMock()
        yield mock_mongo

def test_get_contacts_list(client, mock_mongo):
    # Mock contacts database response
    mock_mongo.db.contacts.find.return_value = [
        {'_id': ObjectId('507f1f77bcf86cd799439011'), 'name': 'John', 'phone': '1234', 'email': 'john@test.com'}
    ]
    
    response = client.get('/contacts')
    assert response.status_code == 200
    assert b'John' in response.data

def test_create_contact_success(client, mock_mongo):
    # Set up mock for database insert
    mock_id = ObjectId('507f1f77bcf86cd799439011')
    mock_mongo.db.contacts.insert_one.return_value = MagicMock(inserted_id=mock_id)
    
    # Test data
    new_contact = {
        'name': 'Alice',
        'phone': '5678',
        'email': 'alice@test.com'
    }
    
    response = client.post('/contacts', json=new_contact)
    assert response.status_code == 201
    assert b'Alice' in response.data

def test_create_contact_no_data(client):
    response = client.post('/contacts', json={})
    assert response.status_code == 400

def test_delete_contact(client, mock_mongo):
    # Mock successful deletion
    mock_mongo.db.contacts.delete_one.return_value = MagicMock(deleted_count=1)
    
    mock_id = '507f1f77bcf86cd799439011'  # Valid 24-char hex string
    response = client.delete(f'/contacts/{mock_id}')
    assert response.status_code == 200

def test_update_contact(client, mock_mongo):
    # Mock successful update
    mock_mongo.db.contacts.update_one.return_value = MagicMock(matched_count=1)
    
    update_data = {
        'name': 'Updated Name',
        'phone': '9999'
    }
    
    mock_id = '507f1f77bcf86cd799439011'  # Valid 24-char hex string
    response = client.put(f'/contacts/{mock_id}', json=update_data)
    assert response.status_code == 200