mock_provider "gitlab" {
  mock_resource "gitlab_group" {
    defaults = { id = "101" }
  }
  mock_resource "gitlab_user" {
    defaults = { id = "201" }
  }
  mock_data "gitlab_user" {
    defaults = { id = "202" }
  }
  mock_resource "gitlab_project" {
    defaults = { id = "301" }
  }
}

mock_provider "artifactory" {}

variables {
  environment = "dev"
}

run "gitlab_onboarding_and_protection" {
  command   = apply
  state_key = "gitlab-onboarding"

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      groups = {
        engineering = { name = "Engineering", path = "engineering" }
      }
      subgroups = {
        platform = { name = "Platform", path = "platform", parent_group_key = "engineering" }
      }
      users = {
        developer = { name = "Developer", email = "developer@example.invalid" }
      }
      existing_users = ["owner"]
      group_memberships = {
        developer = { group_key = "platform", username = "developer" }
        owner     = { group_key = "engineering", username = "owner", access_level = "owner" }
      }
      project_memberships = {
        owner = { project_key = "application", username = "owner", access_level = "maintainer" }
      }
      projects = {
        application = {
          name           = "Application"
          path           = "application"
          group_key      = "platform"
          default_branch = "trunk"
          branch_protections = {
            "release/*" = {}
          }
        }
      }
    }
  }

  assert {
    condition = (
      gitlab_group.subgroups["platform"].parent_id == tonumber(gitlab_group.groups["engineering"].id) &&
      gitlab_project.projects["application"].namespace_id == tonumber(output.group_ids["platform"]) &&
      gitlab_group_membership.memberships["owner"].user_id == tonumber(output.user_ids["owner"]) &&
      gitlab_project_membership.memberships["owner"].project == gitlab_project.projects["application"].id
    )
    error_message = "Groups, projects and memberships must resolve managed and existing IDs."
  }

  assert {
    condition = (
      length(gitlab_branch_protection.branches) == 2 &&
      gitlab_branch_protection.branches[jsonencode(["application", "trunk"])].push_access_level == "no one" &&
      gitlab_branch_protection.branches[jsonencode(["application", "trunk"])].merge_access_level == "maintainer" &&
      !gitlab_branch_protection.branches[jsonencode(["application", "trunk"])].allow_force_push
    )
    error_message = "Protect the actual default branch and additional patterns with restrictive defaults."
  }

  assert {
    condition = (
      gitlab_project.projects["application"].visibility_level == "private" &&
      gitlab_project.projects["application"].only_allow_merge_if_pipeline_succeeds &&
      gitlab_user.users["developer"].force_random_password &&
      gitlab_user.users["developer"].reset_password &&
      !gitlab_user.users["developer"].is_admin
    )
    error_message = "Projects must default to private and users must onboard without administrator rights or supplied passwords."
  }
}

run "gitlab_enterprise_protection" {
  command = plan

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      is_enterprise = true
      groups = {
        team = { name = "Team", path = "team" }
      }
      projects = {
        application = {
          name      = "Application"
          path      = "application"
          group_key = "team"
          branch_protections = {
            main = { should_require_code_owner_approval = true }
          }
        }
      }
    }
  }

  assert {
    condition = (
      length(gitlab_branch_protection.branches) == 1 &&
      one(gitlab_branch_protection.branches[jsonencode(["application", "main"])].allowed_to_push).access_level == "no one" &&
      one(gitlab_branch_protection.branches[jsonencode(["application", "main"])].allowed_to_merge).access_level == "maintainer" &&
      gitlab_branch_protection.branches[jsonencode(["application", "main"])].code_owner_approval_required
    )
    error_message = "Enterprise protection must use access-level sets and override, not duplicate, the default rule."
  }
}

run "gitlab_reject_duplicate_group_keys" {
  command = plan

  module {
    source = "./modules/gitlab"
  }

  variables {
    configuration = {
      groups = {
        team = { name = "Team", path = "team" }
      }
      subgroups = {
        team = { name = "Child", path = "child", parent_group_key = "team" }
      }
    }
  }

  expect_failures = [gitlab_group.subgroups["team"]]
}

run "artifactory_onboarding_and_permissions" {
  command   = apply
  state_key = "artifactory-onboarding"

  module {
    source = "./modules/artifactory"
  }

  variables {
    configuration = {
      groups = { developers = {} }
      users = {
        developer = { email = "developer@example.invalid", groups = ["developers"] }
      }
      local_generic_repositories = { "generic-local" = {} }
      local_docker_repositories  = { "docker-local" = {} }
      virtual_generic_repositories = {
        generic = { repositories = ["generic-local"], default_deployment_repo = "generic-local" }
      }
      virtual_docker_repositories = {
        docker = { repositories = ["docker-local"], default_deployment_repo = "docker-local" }
      }
      permission_targets = {
        publish = {
          repositories      = ["generic-local", "docker-local"]
          group_permissions = { developers = ["read", "write"] }
          user_permissions  = { developer = ["read"] }
        }
      }
    }
  }

  assert {
    condition = (
      !artifactory_group.groups["developers"].admin_privileges &&
      !artifactory_group.groups["developers"].auto_join &&
      !artifactory_user.users["developer"].admin &&
      toset(artifactory_user.users["developer"].groups) == toset(["developers"])
    )
    error_message = "Onboarding must be non-admin, disable automatic group joining and assign the requested groups."
  }

  assert {
    condition = (
      artifactory_virtual_generic_repository.repositories["generic"].default_deployment_repo == "generic-local" &&
      artifactory_virtual_docker_repository.repositories["docker"].default_deployment_repo == "docker-local" &&
      artifactory_local_docker_v2_repository.repositories["docker-local"].block_pushing_schema1 &&
      artifactory_local_docker_v2_repository.repositories["docker-local"].max_unique_tags == 0
    )
    error_message = "Virtual repositories must target local repositories without enabling automatic artifact deletion."
  }

  assert {
    condition = (
      toset(one(artifactory_permission_target.permissions["publish"].repo).repositories) == toset(["generic-local", "docker-local"]) &&
      toset(one(one(one(artifactory_permission_target.permissions["publish"].repo).actions).groups).permissions) == toset(["read", "write"])
    )
    error_message = "Permissions must be restricted to the named repositories and requested actions."
  }
}

run "empty_gitlab" {
  command = plan
  module {
    source = "./modules/gitlab"
  }
  assert {
    condition     = length(output.group_ids) == 0 && length(output.project_ids) == 0 && length(output.user_ids) == 0
    error_message = "Empty GitLab input must create no resources."
  }
}

run "empty_artifactory" {
  command = plan
  module {
    source = "./modules/artifactory"
  }
  assert {
    condition     = alltrue([for repositories in values(output.repository_keys) : length(repositories) == 0])
    error_message = "Empty Artifactory input must create no repositories."
  }
}

run "environment_configuration" {
  command = plan

  assert {
    condition     = toset(keys(output.gitlab_project_ids)) == toset(keys(try(local.gitlab.projects, {})))
    error_message = "Every environment project must be wired through the root module."
  }

  assert {
    condition     = toset(output.artifactory_repository_keys.local_generic) == toset(keys(try(local.artifactory.local_generic_repositories, {})))
    error_message = "Every environment generic repository must be wired through the root module."
  }
}

run "test_environment_configuration" {
  command = plan

  variables {
    environment = "test"
  }

  assert {
    condition = (
      local.gitlab_base_url == "https://gitlab.test.example.internal/api/v4/" &&
      local.artifactory_url == "https://jfrog.test.example.internal/artifactory" &&
      toset(keys(output.gitlab_project_ids)) == toset(["application"]) &&
      toset(output.artifactory_repository_keys.local_generic) == toset(["platform-test-generic-local"])
    )
    error_message = "The test selector must load test endpoints and resource configuration."
  }
}

run "prod_environment_configuration" {
  command = plan

  variables {
    environment = "prod"
  }

  assert {
    condition = (
      local.gitlab_base_url == "https://gitlab.prod.example.internal/api/v4/" &&
      local.artifactory_url == "https://jfrog.prod.example.internal/artifactory" &&
      local.gitlab.groups.engineering.project_creation_level == "owner" &&
      toset(keys(output.gitlab_project_ids)) == toset(["application"]) &&
      toset(output.artifactory_repository_keys.local_generic) == toset(["platform-prod-generic-local"])
    )
    error_message = "The prod selector must load production endpoints, restrictions and resources."
  }
}