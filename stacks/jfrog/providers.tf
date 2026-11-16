provider "artifactory" {
  url = var.jfrog_url
}

provider "platform" {
  url = var.jfrog_url
}

provider "project" {
  url = var.jfrog_url
}

provider "xray" {
  url = var.jfrog_url
}
