# Encrypt a disk with a keyfile through openzfs

1. Find the disk you want to use and make sure it is not mounted
```bash
lsblk -f 
or lsblk -o NAME,SIZE,MODEL,TRAN,SERIAL
```
yielded /dev/sdc

2. Install openzfs tools
```bash
sudo add-apt-repository ppa:openzfs/zfs
sudo apt update
sudo apt upgrade
sudo apt install zfsutils-linux
```

3. Create the key file
```bash
sudo mkdir -p /etc/zfs/keys
sudo chmod 700 /etc/zfs/keys
tr -dc 'A-Za-z0-9*%^$#@' < /dev/urandom | head -c 64 | sudo tee /etc/zfs/keys/emergency-onsite.passphrase > /dev/null
sudo chmod 600 /etc/zfs/keys/emergency-onsite.passphrase
```

4. Make sure the mount folder is there
```bash
sudo mkdir -p /mnt/emergency-onsite
sudo chmod 700 /mnt/emergency-onsite
```

5. Create the zpool and zfs filesystem on the disk
ashift=12 because I'm using a modern hdd, should be different for SSD
```bash
sudo zpool create \
  -O encryption=on \
  -O acltype=posixacl \
  -O compression=lz4 \
  -O relatime=on \
  -O atime=off \
  -o ashift=12 \
  -O xattr=sa \
  -O normalization=formD \
  -O keyformat=passphrase \
  -O keylocation=file:///etc/zfs/keys/hdd-jayc.passphrase \
  -O mountpoint=/mnt/hdd \
  hdd /dev/sda
```



############# load all keys:


```bash
sudo nano /etc/systemd/system/zfs-load-keys.service
```

```bash
[Unit]
Description=Load ZFS encryption keys
DefaultDependencies=no
After=zfs-import.target
Before=zfs-mount.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/zfs load-key -a

[Install]
WantedBy=zfs-mount.service
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable zfs-load-keys.service
```

