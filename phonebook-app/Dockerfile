# Build stage
FROM python:3.9-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Development stage
FROM python:3.9-slim as development
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/
# Don't copy application code - it will be mounted via volume

# Test stage
FROM development as test
WORKDIR /app
COPY tests/ ./tests/
COPY app.py .
COPY templates/index.html ./templates/
RUN pip install --no-cache-dir pytest pytest-mock requests

# Production stage
FROM python:3.9-slim as production
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/
# COPY app.py .
# COPY requirements.txt .
# COPY templates/ templates/
COPY . .


EXPOSE 5000
CMD ["python", "app.py"]
