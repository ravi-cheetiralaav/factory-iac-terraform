terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    artifactory = {
      source  = "jfrog/artifactory"
      version = ">= 12.11.14, < 13.0.0"
    }
  }
}