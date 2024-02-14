
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