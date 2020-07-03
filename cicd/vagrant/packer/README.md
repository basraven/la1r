# Packer files
The packer files from this repo are sourced from:
https://github.com/chef/bento/tree/master/packer_templates

## Run

### Cretae a virtual network adapter names ```Standardswitch``` in hyperv
```powershell
$VS = "Standardswitch"
$IF_ALIAS = (Get-NetAdapter -Name "vEthernet ($VS)").ifAlias
New-NetFirewallRule -Displayname "Allow incomming from $VS" -Direction Inbound -InterfaceAlias $IF_ALIAS -Action Allow
```

### Run packer
```powershell
cd ubuntu
packer build -only=hyperv-iso .\ubuntu-20.04-amd64.json
```

### TODO
TODO: Raspberry pi
https://gist.github.com/Manu343726/ca0ceb224ea789415387