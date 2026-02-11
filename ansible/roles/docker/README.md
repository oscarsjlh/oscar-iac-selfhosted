Docker Role
============

This Ansible role deploys Docker services by copying entire service directories and running Docker Compose. It handles all file types including configuration files, scripts, and docker-compose files.

Requirements
------------

- Docker and Docker Compose installed on target hosts
- community.docker Ansible collection

Role Variables
--------------

This role uses hardcoded paths but can be customized by modifying the source path in tasks/main.yml:

- `docker_source_path`: Source directory containing Docker service folders (default: "/home/oscar/projects/iac/docker/")
- `docker_user`: User ownership for copied files (default: "oscar")
- `docker_group`: Group ownership for copied files (default: "oscar")

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

What it does
-----------

1. **Discovers Docker services**: Finds all directories in the source docker folder
2. **Creates directories**: Creates corresponding directories on remote hosts
3. **Copies all content**: Recursively copies entire service directories including:
   - docker-compose.yaml files
   - Configuration files (e.g., prometheus.yaml, blackbox.yaml)
   - Scripts and executable files
   - Any subdirectories and their contents
4. **Preserves permissions**: Maintains file permissions and ensures shell scripts are executable
5. **Deploys services**: Runs `docker compose up` for each service

Directory Structure
------------------

Expected source structure:
```
docker/
├── service1/
│   ├── docker-compose.yaml
│   ├── config.yml
│   └── scripts/
│       └── init.sh
├── service2/
│   ├── docker-compose.yaml
│   ├── prometheus.yaml
│   └── blackbox.yaml
```

Example Playbook
----------------

```yaml
- hosts: docker_hosts
  roles:
    - docker
```

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
