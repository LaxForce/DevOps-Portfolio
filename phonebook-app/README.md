# Phonebook Application

A modern, responsive web-based phonebook application built with Flask and MongoDB, featuring real-time updates and prometheus metrics integration.

## Features

- Create, Read, Update, and Delete (CRUD) contacts
- Responsive design that works on desktop and mobile
- Dark/Light theme support
- Contact notes with modal editing
- Real-time updates
- Prometheus metrics integration
- Comprehensive logging
- MongoDB database backend

## Tech Stack

- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Backend**: Python Flask
- **Database**: MongoDB
- **Monitoring**: Prometheus
- **Containerization**: Docker
- **Logging**: Python logging module

## Prerequisites

- Docker and Docker Compose
- MongoDB
- Python 3.8+
- pip (Python package manager)

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd phonebook-app
   ```

2. Create a virtual environment (optional but recommended):
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: .\venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
MONGO_USERNAME=your_username
MONGO_PASSWORD=your_password
MONGO_DATABASE=phonebook
MONGO_ROOT_USERNAME=root_username
MONGO_ROOT_PASSWORD=root_password
```

## Running the Application

### Using Docker Compose (Recommended)

1. Start the application:
   ```bash
   docker compose up -d
   ```

2. Access the application at `http://localhost:80`

### Manual Setup

1. Ensure MongoDB is running locally

2. Start the Flask application:
   ```bash
   python app.py
   ```

3. Access the application at `http://localhost:5000`

## Testing

The application includes both unit tests and end-to-end (e2e) tests.

### Running Tests with Docker (Recommended)

Run unit tests:
```bash
docker compose run --build unit-test-runner
```

Run e2e tests:
```bash
docker compose run test-runner
```

```bash
docker compose up --build
```  - e2e runs when you bring the whole app up.

Run both test suites:
```bash
docker compose run --build unit-test-runner && docker compose run test-runner
```

### Test Structure

```
tests/
│ 
└── test_app.py
└── test_e2e.py

```

- Unit tests cover individual endpoint functionality without external dependencies
- E2E tests verify the complete application flow with all services running

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/contacts` | Retrieve all contacts |
| GET | `/contacts/{id}` | Retrieve a specific contact |
| POST | `/contacts` | Create a new contact |
| PUT | `/contacts/{id}` | Update an existing contact |
| DELETE | `/contacts/{id}` | Delete a contact |
| GET | `/metrics` | Prometheus metrics endpoint |

## Monitoring

The application exposes Prometheus metrics at the `/metrics` endpoint, including:
- Total request counts by endpoint and method
- Response time histograms
- Custom business metrics

## Project Architecture

```
phonebook-app/
├── app.py              # Main Flask application
├── templates/
│   └── index.html      # Frontend HTML template
├── tests/
│   ├── unit/          # Unit tests
│   └── test_e2e.py    # E2E tests
├── docker-compose.yml  # Docker compose configuration
├── Dockerfile         # Docker build configuration
├── requirements.txt   # Python dependencies
├── .env              # Environment variables
└── nginx.conf        # Nginx configuration
```

## Development

### Adding New Features

1. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and test thoroughly

3. Submit a pull request

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## Troubleshooting

Common issues and their solutions:

1. **MongoDB Connection Issues**
   - Verify environment variables in `.env`
   - Check if MongoDB container is running: `docker compose ps`
   - Review logs: `docker compose logs mongodb`

2. **Test Failures**
   - Ensure all services are down before running tests
   - Clean Docker environment: `docker compose down --rmi all --volumes`
   - Check test logs for specific failures
