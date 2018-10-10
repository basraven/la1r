docker network create --driver bridge ansible-testnet
docker build . -t raspi
docker rm raspi1 raspi2 raspi3 --force
docker run --name raspi1 --hostname raspi1 --privileged --net ansible-testnet -d raspi
docker run --name raspi2 --hostname raspi2 --privileged --net ansible-testnet -d raspi
docker run --name raspi3 --hostname raspi3 --privileged --net ansible-testnet -d raspi
