# Encrypt a disk with a keyfile through openzfs

1. Find the disk you want to use and make sure it is not mounted
```bash
lsblk -f 
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
  -o ashift=12 \
  -O xattr=sa \
  -O normalization=formD \
  -O keyformat=passphrase \
  -O keylocation=file:///etc/zfs/keys/emergency-onsite.passphrase \
  -O mountpoint=/mnt/emergency-onsite \
  emergency-onsite /dev/sdc
```

### All the stuff below doesn't work, the backup script mounts itself as first step

6. Make systemd service
sudo nano /etc/systemd/system/zfs-load-key@emergency-onsite.service
```bash
[Unit]
Description=Load ZFS encryption key for emergency-onsite
DefaultDependencies=no
Before=zfs-mount.service
After=zfs-import.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/zfs load-key emergency-onsite
RemainAfterExit=yes

[Install]
WantedBy=zfs-import.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable zfs-load-key@emergency-onsite.service
```
