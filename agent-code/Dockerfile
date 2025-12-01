# Use a lightweight base image for Python applications
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the Python code into the container
COPY agent.py .

# Command to run your agent when the container starts
CMD ["python", "agent.py"]