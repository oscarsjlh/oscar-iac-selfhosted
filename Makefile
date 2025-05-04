ansiblePath = ./ansible/
ansibleCommand = ansible-playbook -i $(ansiblePath)hosts $(ansiblePath)
deploy_systemd:
	$(ansibleCommand)systemd.yaml
deploy_docker:
	$(ansibleCommand)docker.yaml
deploy_pull:
	$(ansibleCommand)pull.yaml
deploy_updates:
	$(ansibleCommand)updates.yaml 

update: deploy_pull deploy_updates
