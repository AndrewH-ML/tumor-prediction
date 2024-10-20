# Dockerfile

# Build stage
FROM python:3.11-slim AS builder

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Runtime stage
FROM python:3.11-slim

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

COPY --from=builder /install /usr/local

COPY ..

RUN chown -R appuser:appgroup /app

USER appuser

# Set environment variables
ENV FLASK_APP=service
ENV FLASK_ENV=production
ENV GUNICORN_CMD_ARGS="--timeout 120" 
# Expose the application port
EXPOSE 5000

# Run the Flask app using Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "service:app"]

