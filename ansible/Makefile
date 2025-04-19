deploy_systemd:
	ansible-playbook -i hosts systemd.yaml
deploy_docker:
	ansible-playbook -i hosts docker.yaml
deploy_pull:
	ansible-playbook -i hosts pull.yaml
deploy_updates:
	ansible-playbook ./updates.yaml -i hosts

update: deploy_pull deploy_updates
