# Terraform Project Setup Guide

## Project Overview

This is a **GitLab and Artifactory Day-2 Terraform** project that manages:
- GitLab groups, subgroups, projects, users, and policies
- Artifactory repositories, access control, and administration
- JFrog Projects paired with GitLab projects
- Remote state stored in Azure with Azure AD authentication

**Note:** This project does NOT provision the underlying infrastructure or install services.

---

## Prerequisites

### Required Tools
- **Terraform** >= 1.10.0, < 2.0.0
- **Azure CLI** (for Azure backend authentication)
- **GitLab API Access** (token or authentication method)
- **Artifactory API Access** (token)

### Required Providers
```
- gitlab (gitlabhq/gitlab) - version 19.5.0
- artifactory (jfrog/artifactory) - version 12.11.14
- project (jfrog/project) - version 1.9.9
```

---

## Setup Steps

### Step 1: Authenticate with Azure (Backend)

The project uses Azure backend with Azure AD authentication. Set up Azure authentication:

```bash
# Login to Azure
az login

# Set your Azure subscription (if not already set)
az account set --subscription "<subscription-id>"

# Verify authentication
az account show
```

**Backend Configuration Details:**
- Backend type: `azurerm`
- Authentication: `use_azuread_auth = true` (Azure AD-based)
- You'll need to create or reference:
  - Azure Storage Account
  - Blob Container for state
  - Resource Group

### Step 2: Configure Azure Backend (if not already done)

Before running Terraform, ensure the Azure backend storage is set up:

```bash
# Create Resource Group (if needed)
az group create --name <rg-name> --location <region>

# Create Storage Account
az storage account create \
  --name <storage-account-name> \
  --resource-group <rg-name> \
  --location <region> \
  --sku Standard_LRS

# Create Blob Container
az storage container create \
  --name terraform-state \
  --account-name <storage-account-name>
```

### Step 3: Initialize the Backend

Create a backend configuration file or use environment variables:

```bash
# Option A: Using backend config file (backend-config.hcl)
terraform init -backend-config="backend-config.hcl"

# Option B: Using command-line flags
terraform init \
  -backend-config="resource_group_name=<rg-name>" \
  -backend-config="storage_account_name=<storage-account-name>" \
  -backend-config="container_name=terraform-state" \
  -backend-config="key=terraform.tfstate"

# Option C: Using environment variables
export ARM_RESOURCE_GROUP_NAME="<rg-name>"
export ARM_STORAGE_ACCOUNT_NAME="<storage-account-name>"
export ARM_CONTAINER_NAME="terraform-state"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
terraform init
```

### Step 4: Set Up Environment Configuration

Choose your environment: **lab01**, **e01**, or **w01**

1. **Create/verify configuration files** for your environment:
   - `environments/<environment>/gitlab.json` - GitLab hierarchy and configuration
   - `environments/<environment>/jfrog.json` - Artifactory configuration

2. **Example gitlab.json structure:**
   ```json
   {
     "gitlab_base_url": "https://gitlab.lab01.example.internal/api/v4/",
     "gitlab": {
       "groups": {
         "platform": {
           "name": "Platform Group",
           "path": "platform",
           "subgroups": {
             "subgroup-key": {
               "name": "Subgroup Name",
               "path": "subgroup-path",
               "projects": {
                 "project-key": {
                   "name": "Project Name",
                   "path": "project-path"
                 }
               }
             }
           }
         }
       }
     }
   }
   ```

3. **Example jfrog.json structure:**
   ```json
   {
     "artifactory_url": "https://jfrog.lab01.example.internal/artifactory",
     "artifactory": {
       "defaults": {
         "robot_email_domain": "lab01.example.internal"
       },
       "access": {
         "groups": {},
         "users": {},
         "permission_targets": {}
       },
       "repositories": {
         "local": {
           "generic": {},
           "docker": {},
           "maven": {}
         },
         "virtual": {
           "generic": {},
           "docker": {}
         }
       }
     }
   }
   ```

### Step 5: Set Up Provider Authentication

#### GitLab Authentication

Set the GitLab personal access token:

```bash
# Option A: Environment variable
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"

# Option B: In your shell profile (~/.bashrc, ~/.zshrc, etc.)
export GITLAB_TOKEN="<your-gitlab-pat>"
```

**How to create a GitLab Personal Access Token:**
1. Log in to GitLab
2. Go to **Settings → Access Tokens** (or **User → Settings → Access Tokens**)
3. Create a new token with scopes:
   - `api` - Full API access
   - `read_user` - Read user information
   - `read_repository` - Read repository contents
4. Copy the token (you won't be able to see it again)

#### Artifactory Authentication

Set the Artifactory API token:

```bash
# Option A: Environment variable
export ARTIFACTORY_URL="https://jfrog.lab01.example.internal/artifactory"
export ARTIFACTORY_API_KEY="<your-artifactory-api-key>"

# Option B: Username and password (if API key not available)
export ARTIFACTORY_USERNAME="<username>"
export ARTIFACTORY_PASSWORD="<password>"
```

**How to get Artifactory API Key:**
1. Log in to Artifactory
2. Go to **User Profile → Edit Profile**
3. Click on **API Key** tab
4. Generate or copy your API key

### Step 6: Validate Configuration

```bash
# Check Terraform syntax
terraform fmt -check -recursive

# Validate Terraform configuration
terraform validate
```

### Step 7: Plan and Apply

```bash
# Set the environment variable
export TF_VAR_environment="lab01"

# (Optional) If you have SMTP or OAuth secrets
export TF_VAR_artifactory_secrets='{"mail_password":"password","oauth_client_secrets":{"provider":"secret"}}'

# Plan the deployment
terraform plan -out=tfplan

# Review the plan output carefully

# Apply the configuration
terraform apply tfplan
```

---

## GitLab Authentication Deep Dive (GitLab.com)

### Provider Configuration

The GitLab provider is configured in [providers.tf](/providers.tf):

```hcl
provider "gitlab" {
  base_url = local.gitlab_base_url
}
```

The `base_url` is read from `local.gitlab_base_url`, which comes from `environments/<environment>/gitlab.json`:

```json
{
  "gitlab_base_url": "https://gitlab.com/api/v4/"
}
```

### Authentication Methods

The GitLab provider uses the `GITLAB_TOKEN` environment variable by default:

```bash
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
```

### How to Create a GitLab Personal Access Token (GitLab.com)

1. **Log in to GitLab.com**
   - Go to https://gitlab.com

2. **Navigate to Access Tokens**
   - Click on your avatar in the top-right corner
   - Select **Preferences** or go to https://gitlab.com/-/profile/personal_access_tokens

3. **Create a New Token**
   - Click **Add new token**
   - **Token name:** e.g., `terraform-token`
   - **Expiration date:** Choose an appropriate date (or leave blank for no expiration)
   - **Scopes (select all these):**
     - ✅ `api` - Full API access
     - ✅ `read_api` - Read-only API access (optional, but recommended alongside `api`)
     - ✅ `read_user` - Read user information
     - ✅ `read_repository` - Read repository contents
     - ✅ `write_repository` - Write to repositories (if needed for project creation)

4. **Copy the Token**
   - GitLab shows the token only once - copy it immediately
   - Store it securely (never commit to Git!)

5. **Set Environment Variable**
   ```bash
   export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
   ```

### Required Permissions

Your GitLab token needs these minimum permissions:
- ✅ `api` - Full API access for all operations
- ✅ `read_user` - Read user information
- ✅ `read_repository` - Read repository details

### Token Expiration & Renewal

GitLab tokens can expire. Monitor token expiration:

```bash
# In GitLab.com UI: 
# Settings → Access Tokens (https://gitlab.com/-/profile/personal_access_tokens)
# Token details show: "Expires on [date]"
```

When a token expires, create a new one and update your environment variable:

```bash
export GITLAB_TOKEN="glpat-new-token-here"
```

### Verify GitLab.com Authentication

Test your token with a simple API call:

```bash
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
     "https://gitlab.com/api/v4/user"
```

Expected output: Your GitLab user information in JSON format

---

## Environment-Specific Setup

The project supports three environments: **lab01**, **e01**, **w01**

### For Each Environment

1. **Create configuration files:**
   ```
   environments/<environment>/gitlab.json
   environments/<environment>/jfrog.json
   ```

2. **Use environment variable when running Terraform:**
   ```bash
   export TF_VAR_environment="lab01"
   terraform plan
   ```

3. **Separate state files per environment:**
   - Each environment uses its own remote state in Azure
   - Configure backend appropriately for each environment

---

## Common Commands

```bash
# Initialize Terraform
terraform init

# Format configuration
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
export TF_VAR_environment="lab01"
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan

# Destroy resources
terraform destroy

# Show current state
terraform state list
terraform state show <resource>

# Refresh state from remote
terraform refresh

# Unlock state (if locked)
terraform force-unlock <lock-id>
```

---

## Troubleshooting

### Azure Backend Issues

**Error: "Unauthorized" when initializing backend**
```bash
# Verify Azure authentication
az account show

# Re-authenticate if needed
az login
```

**Error: "Failed to authenticate"**
```bash
# Check environment variables
echo $ARM_SUBSCRIPTION_ID
echo $ARM_TENANT_ID

# Verify storage account exists
az storage account show --name <storage-account-name> --resource-group <rg-name>
```

### GitLab Provider Issues

**Error: "401 Unauthorized"**
- Verify token is set: `echo $GITLAB_TOKEN`
- Check token has not expired
- Verify token has correct permissions
- Confirm GitLab base URL is correct and accessible

**Error: "Connection refused"**
- Verify GitLab URL is accessible
- Check network connectivity and firewall rules
- Verify URL matches your GitLab instance

### Artifactory Provider Issues

**Error: "Authentication failed"**
- Verify API key or username/password
- Check Artifactory URL is correct
- Verify user has appropriate permissions
- Confirm API key has not expired

---

## Configuration Management

### JSON Configuration Rules

✅ **DO:**
- Use valid JSON syntax
- Keep configuration in environment-specific directories
- Use `{}` for empty optional maps
- Keep keys stable (renaming causes destroy/recreate)

❌ **DON'T:**
- Include comments in JSON files
- Add trailing commas
- Store passwords or tokens in JSON
- Use unquoted strings or values

### Best Practices

1. **Version control** - Commit `gitlab.json` and `jfrog.json` to Git
2. **Secrets management** - Use environment variables or Vault for sensitive data
3. **State management** - Never commit `.terraform/` or `*.tfstate` files
4. **Review changes** - Always run `terraform plan` and review before `apply`
5. **Backup state** - Ensure Azure storage backup is configured

---

## Next Steps

1. ✅ Install Terraform >= 1.10.0
2. ✅ Configure Azure authentication
3. ✅ Create environment configuration files
4. ✅ Set GitLab and Artifactory tokens
5. ✅ Run `terraform init`
6. ✅ Run `terraform plan`
7. ✅ Review and apply with `terraform apply`

---

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitLab Provider Documentation](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Artifactory Provider Documentation](https://registry.terraform.io/providers/jfrog/artifactory/latest/docs)
- [JFrog Project Provider Documentation](https://registry.terraform.io/providers/jfrog/project/latest/docs)
