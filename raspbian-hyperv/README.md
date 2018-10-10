# Hyper-v Raspbians
These are test hyper-v machines with Raspbian for testing purposes

## How to use
```powershell
run.ps1
```


## Solving slow/timemout of right escalation (sudo):
Update the /etc/hosts file on the Raspbians manually with (replace piname):
```conf
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
127.0.0.1       piname
127.0.1.1       piname
```