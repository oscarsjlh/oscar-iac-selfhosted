deploy_systemd:
	cd ./ansible/
	ansible-playbook -i hosts systemd.yaml
deploy_docker:
	cd ./ansible/
	ansible-playbook -i hosts docker.yaml
deploy_pull:
	cd ./ansible/
	ansible-playbook -i hosts pull.yaml
deploy_updates:
	cd ./ansible/
	ansible-playbook ./updates.yaml -i hosts

update: deploy_pull deploy_updates
