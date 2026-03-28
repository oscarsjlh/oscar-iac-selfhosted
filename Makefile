ansiblePath = ./ansible/
ansibleCommand = ansible-playbook -i $(ansiblePath)hosts $(ansiblePath)

# Docker deployment targets
deploy_docker: deploy_docker_remote

deploy_docker_remote:
	$(ansibleCommand)docker.yaml

deploy_docker_local:
	$(ansibleCommand)docker-local.yaml

# Systemd deployment targets
deploy_systemd:
	$(ansibleCommand)systemd.yaml

# Other deployment targets
deploy_pull:
	$(ansibleCommand)pull.yaml
deploy_updates:
	$(ansibleCommand)updates.yaml 
deploy_ci_user:
	$(ansibleCommand)ci-user.yaml

# Deploy to all hosts (local + remote)
deploy_all: deploy_docker_local deploy_docker_remote

update: deploy_pull deploy_updates

# CI Docker image
REGISTRY = registry.oscarcorner.com
CI_IMAGE = $(REGISTRY)/oscar/ansible-ci:latest

build_ci_image:
	docker build -t $(CI_IMAGE) -f Dockerfile.ci .

push_ci_image:
	docker push $(CI_IMAGE)

ci_image: build_ci_image push_ci_image
