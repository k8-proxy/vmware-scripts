sudo apt update
sudo apt upgrade -y
sudo apt-get install \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"
sudo apt update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo docker pull minio/minio:latest
sudo docker run -d --restart=always -p 80:9000 \
  --name minio1 \
  -v /mnt/data:/data \
  -e "MINIO_ACCESS_KEY=user" \
  -e "MINIO_SECRET_KEY=secret_password" \
  minio/minio server /data
