# Use the official Python image from the DockerHub
FROM python:3.12.8-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt and install dependencies
COPY requirements.txt /app/
RUN pip install -r requirements.txt

# Copy the rest of the application code
COPY . /app/

# Expose port 5000
EXPOSE 5000

# Command to run the app
CMD ["python", "app.py"]
