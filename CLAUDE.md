<!-- gortex:communities:start -->
<!-- gortex:skills:start -->
## Community Skills

| Area | Description | Skill |
|------|-------------|-------|
| Scripts Backup | 4 symbols | `/gortex-scripts-backup` |
<!-- gortex:skills:end -->

<!-- gortex:communities:end -->

## Repository deployment model

This repository is a GitOps-style definition of the services running on the remote
server. The Docker Compose projects under `docker/` are not deployed by running
Compose from this checkout: Ansible copies them to the remote host and starts or
updates them there.

- Use `make deploy_docker_remote` (or `ansible-playbook -i ansible/hosts ansible/docker.yaml`)
  to deploy the remote Docker services.
- `ansible/docker.yaml` targets the `[remote]` inventory group and runs the `docker`
  role with privilege escalation.
- Changes to remote services, including monitoring and Vector, should be made in
  this repository and then synchronized with Ansible.
- `make deploy_docker_local` is a separate workflow for the `[local]` host; do not
  assume that a local Compose run updates the remote server.
