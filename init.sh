
set -a
source .env
set +a


docker network create picklebook-network

docker volume create picklebook-user-uploads
docker volume create picklebook-user-guides
docker volume create picklebook-prometheus-data
docker volume create picklebook-grafana-data
docker volume create picklebook-loki-data
docker volume create picklebook-rabbitmq-data
docker volume create picklebook-rabbitmq-logs
docker volume create picklebook-mysql-data
docker volume create picklebook-redis-data


rm -rf picklebook-bootstrap

git clone https://github.com/picklebook/picklebook-bootstrap.git --depth=1 -q


cp picklebook-bootstrap/docker-compose-master-* .
cp picklebook-bootstrap/*.yaml .
cp picklebook-bootstrap/*.sh .
chmod +x *.sh

