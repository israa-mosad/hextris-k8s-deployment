variable "docker_image_repo" {
  description = "The repository path for the Docker image (e.g., israa2000/hextris)"
  type        = string
}

variable "docker_image_tag" {
  description = "The tag for the Docker image (e.g., latest or a CI build ID)"
  type        = string
}
