locals {
  project_files = fileset("${path.module}/../../catalog/jfrog/projects", "*.yaml")
}

module "global" {
  source = "../../modules/artifactory-global"

  spec                    = yamldecode(file("${path.module}/../../catalog/jfrog/global.yaml"))
  manage_general_security = var.manage_general_security
  enable_anonymous_access = var.enable_anonymous_access
  encryption_policy       = var.encryption_policy
}

module "project" {
  source   = "../../modules/artifactory-project"
  for_each = local.project_files

  spec                              = yamldecode(file("${path.module}/../../catalog/jfrog/projects/${each.value}"))
  manage_project_permission_targets = var.manage_project_permission_targets

  depends_on = [module.global]
}

output "local_repository_keys" {
  value = module.global.local_repository_keys
}

output "security_policy_names" {
  value = module.global.security_policy_names
}

output "watch_names" {
  value = module.global.watch_names
}

output "projects" {
  value = {
    for name, project in module.project : name => {
      project_key             = project.project_key
      local_repository_keys   = project.local_repository_keys
      virtual_repository_keys = project.virtual_repository_keys
      group_names             = project.group_names
    }
  }
}
