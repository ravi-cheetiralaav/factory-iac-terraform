terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "19.5.0"
    }
    artifactory = {
      source  = "jfrog/artifactory"
      version = "12.11.14"
    }
    project = {
      source  = "jfrog/project"
      version = "1.9.9"
    }
  }
}