variable "aws_region" {
  description = "The AWS region to deploy resources."
  default     = "us-west-2"
}

variable "flask_image" {
  description = "The Docker image for the Flask API"
  type        = string
}
