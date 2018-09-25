docker network create --driver bridge ansible-testnet
docker build . -t raspi-test
docker rm raspi1 raspi2 raspi3 --force
docker run --name raspi1 --net ansible-testnet -td raspi-test /bin/bash
docker run --name raspi2 --net ansible-testnet -td raspi-test /bin/bash
docker run --name raspi3 --net ansible-testnet -td raspi-test /bin/bash
docker exec raspi1 service ssh start
docker exec raspi2 service ssh start
docker exec raspi3 service ssh start
