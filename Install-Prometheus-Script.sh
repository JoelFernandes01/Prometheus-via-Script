#----------------------------------------------------------------------------
# Instalação automatizada do Prometheus no Ubuntu Server 22.04
#
# Download da ISO do Ubuntu Server
# https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso
#----------------------------------------------------------------------------
# Desenvolvido e personalizado por Joel Fernandes
# Meus contatos :
# - Celular:  (61) 98468-1921
# - Linkedin: https://www.linkedin.com/in/joel-fernandes-25838425/
# - Facebook: https://www.facebook.com/JoelFernandesSilvaFilho/
#
# Pré-requistos
# Acesso como root ou com previlégios de root
# Usuário e grupo do Prometheus
# Portas 9090 (Prometheus), 3000 (Grafana) e (9100) Node Exporter do próprio Prometheus
#
# Atualização dos pacotes do Ubuntu Server
sudo apt update -y

# Nomeando o servidor
sudo hostnamectl set-hostname prometheus-server
sed -i 's/'$inet_value'   ubuntu/'$inet_value'   prometheus-server/' /etc/hosts

# Extrair o valor inet da primeira placa de rede excluindo a interface "lo" e armazenar em uma variável
inet_value=$(ifconfig | awk '/inet / && $1 !~ /lo/{gsub("addr:",""); print $2; exit}')

echo "Criando e configurando o usuário do Prometheus"
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
chown prometheus:prometheus /var/lib/prometheus

echo "Baixanhando, verificando e instalando o pacote Prometheus"
cd /opt/
wget https://github.com/prometheus/prometheus/releases/download/v2.49.1/prometheus-2.49.1.linux-amd64.tar.gz
sudo sha256sum /opt/prometheus-2.49.1.linux-amd64.tar.gz
sudo tar -xvf /opt/prometheus-2.49.1.linux-amd64.tar.gz
cd prometheus-2.49.1.linux-amd64
sudo mv /opt/prometheus-2.49.1.linux-amd64/console* /etc/prometheus
sudo mv /opt/prometheus-2.49.1.linux-amd64/prometheus.yml /etc/prometheus
sudo mv /opt/prometheus-2.49.1.linux-amd64/prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
prometheus --version
sleep 3
promtool --version

cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
sed -i 's/localhost/prometheus-server/' /etc/prometheus/prometheus.yml
sudo ufw allow 9090/tcp
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus

echo "Parabéns, seu Sistema Prometheus foi instalado com sucesso !"
#==     show access url ==#
echo    "########============================================########"
echo    "######## URL de acesso : http://'$inet_value':9090    ########"
echo    "########============================================########"
sleep 10

echo "# Instalando e configurando o Node_Exporter"
echo "Preparando o ambiente"
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
sudo tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
sudo useradd -rs /bin/false node_exporter

echo "Criando o serviço do node_exporter"
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]

Description=Node Exporter

After=network.target

[Service]

User=node_exporter

Group=node_exporter

Type=simple

ExecStart=/usr/local/bin/node_exporter

[Install]

WantedBy=multi-user.target
EOF
## Execute os comandos abaixo para iniciar e verificar o status do serviço
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter

echo "Adicionando seção no arquivo de configuração do Prometheus"
echo "  - job_name: 'prometheus-node'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          hostname: prometheus
          type: linux" >> /etc/prometheus/prometheus.yml

# Mudando o nome localhost em /etc/prometheus/prometheus.yml
sed -i 's/localhost/prometheus-server/g' /etc/prometheus/prometheus.yml

sudo systemctl restart node_exporter
sudo systemctl restart prometheus