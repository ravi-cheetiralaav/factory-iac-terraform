provider "gitlab" {
  base_url = local.gitlab_base_url
}

provider "artifactory" {
  url = local.artifactory_url
}

provider "project" {
  url = trimsuffix(trimsuffix(local.artifactory_url, "/"), "/artifactory")
}