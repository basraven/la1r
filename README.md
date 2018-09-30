# server-configs
A personal collection of server configs, enjoy!

## Components
* [/ansible-control](/ansible-control): A control host for Ansible in a Docker container
* [/raspberry-pi-test-env](/raspberry-pi-test-env): A raspbian test environment in Docker
* [/playbooks](/playbooks): A playbooks collection to manage servers
* [/credentials](/credentials): A collection of Ansible Vault secrets

## Running on Windows with Powershell
Sometimes Powershell gives the error "run.ps1 is not digitally signed. You cannot run this script on the current system."
Please use the following command in a Powershell window as Administrator to (permanently solve this)
```powershell
Set-ExecutionPolicy unrestricted
```
