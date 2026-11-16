terraform {
  required_version = ">= 1.9.0"

  required_providers {
    artifactory = {
      source  = "jfrog/artifactory"
      version = ">= 12.11.14"
    }
    platform = {
      source  = "jfrog/platform"
      version = ">= 2.2.11"
    }
    xray = {
      source  = "jfrog/xray"
      version = ">= 3.1.13"
    }
  }
}
