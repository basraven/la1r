# Playbooks
A playbooks collection to manage servers

## File structure
The file structure of these playbooks is based on [Ansible's best practices](https://docs.ansible.com/ansible/latest/user_guide/ansible_best_practices.html)


## How to use
To run the master playbook, run the following:
```bash
ansible-playbook -i raspberry hosts.yml
```


## Running on Windows with Powershell
Sometimes Powershell gives the error "run.ps1 is not digitally signed. You cannot run this script on the current system."
Please use the following command in a Powershell window as Administrator to (permanently solve this)
```powershell
Set-ExecutionPolicy unrestricted
```
