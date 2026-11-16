terraform {
  required_version = ">= 1.9.0"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 19.5.0"
    }
  }
}
