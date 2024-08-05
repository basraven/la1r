# How to use
Run any of the shell files, these will directly deploy the remote machine in an as idempotent way as possible.

https://github.com/basraven/la1r/tree/rick/cicd/ansible

## OpenVPN
All command needed to manage openvpn

## Init new OpenVPN CA (don't!)
```ansible-playbook -i hosts.yml ./init-openvpn-server.yaml```

## To create a new openvpn user 
```ansible-playbook -i hosts.yml ./create-openvpn-user.yaml --extra-vars "openvpn_user=testseb"```

## To delete an openvpn user 
```ansible-playbook -i hosts.yml ./delete-openvpn-user.yaml --extra-vars "openvpn_user=testseb"```