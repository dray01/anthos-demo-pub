# anthos-demo-priv

## Intent of repo
To provide me with a quick way to deploy a base environment that is used for customer facing demo's
Products to demo
- Anthos
- Anthos Service Mesh
- Anthos Config Management
- Anthos Config Connector
- Stackdriver
- Hipster shop sample app

### Pre-reqs

1. gcloud installed on local machine
2. git installed on local machine
3. terraform

## Instructions on using the repo

1. Edit the project/terraform.tfvars with input variables.
2. Edit gke/terraform.tfvars file with desired variables.
3. Map the same project id etc into asm-install.sh script.
4. cd into project dir and execute `terraform init`
5. Plan the build with `terraform plan`
6. execute the project build with `terraform apply`
7. `cd ../gke` and repeat the `init, plan & apply` steps
8. Copy the acm_git_creds_public into your git repo as ssh key
9. Once build is complete `cd ..` back to root dir
10. Ensure you can execute asm-install.sh `chmod 700 asm-install.sh` 
11. Execute `./asm-install.sh`
12. Browse to external site and ensure your boutique shop is operational
13. Browse to console -> Anthos -> Clusters and follow steps in UI to register existing cluster


