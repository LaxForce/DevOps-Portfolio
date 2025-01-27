import os
import pytest
import requests
import json
import time

class TestE2E:
    """End-to-end tests for the phonebook application"""
    # Get host from environment variable or default to 'app'
    host = os.getenv('APP_HOST', 'nginx')
    base_url = f'http://{host}'

    # def test_nginx_response(self):
    #     response = requests.get(f'{self.BASE_URL}/')
    #     assert response.status_code == 200, f"Nginx did not respond as expected: {response.status_code}"
    #     assert "<title>Phonebook Application</title>" in response.text, "Unexpected or missing title in the response"
    #     assert "<h1>Phonebook</h1>" in response.text, "Unexpected or missing header in the response"


    
    def setup_method(self):
        """Setup: wait for services to be ready"""
        retries = 5
        while retries > 0:
            try:
                requests.get(f'{self.base_url}/')
                break
            except requests.ConnectionError:
                retries -= 1
                time.sleep(2)
        if retries == 0:
            pytest.fail("Could not connect to the application")

    
    def test_full_workflow(self):
        """Test complete workflow of creating, reading, updating, and deleting a contact"""
        # Create a contact
        contact_data = {
            'name': 'E2E Test User',
            'phone': '1234567890',
            'email': 'e2e@test.com',
            'notes': 'E2E test notes'
        }
        response = requests.post(f'{self.base_url}/contacts', json=contact_data)
        assert response.status_code == 201
        contact_id = response.json()['_id']['$oid']
        
        # Get the contact
        response = requests.get(f'{self.base_url}/contacts/{contact_id}')
        assert response.status_code == 200
        assert response.json()['name'] == contact_data['name']
        
        # Update the contact
        update_data = {
            'name': 'Updated E2E User',
            'phone': '0987654321'
        }
        response = requests.put(f'{self.base_url}/contacts/{contact_id}', json=update_data)
        assert response.status_code == 200
        
        # Verify update
        response = requests.get(f'{self.base_url}/contacts/{contact_id}')
        assert response.status_code == 200
        assert response.json()['name'] == update_data['name']
        
        # Delete the contact
        response = requests.delete(f'{self.base_url}/contacts/{contact_id}')
        assert response.status_code == 200
        
        # Verify deletion
        response = requests.get(f'{self.base_url}/contacts/{contact_id}')
        assert response.status_code == 404

    def test_service_health(self):
        """Test that all main endpoints are responding"""
        # Test home page
        response = requests.get(f'{self.base_url}/')
        assert response.status_code == 200
        
        # Test contacts endpoint
        response = requests.get(f'{self.base_url}/contacts')
        assert response.status_code == 200
        
        # Test metrics endpoint
        response = requests.get(f'{self.base_url}/metrics')
        assert response.status_code == 200
