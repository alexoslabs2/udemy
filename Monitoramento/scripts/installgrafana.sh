# Script to Install Grafana and Prometheus with Apache and MySQL exporters
# Autor: Alexos (alexos at alexos fot org)
#! /bin/bash

LOG=~/grafana.log
DB_PASSWORD=Secret

#Check sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt-get update > $LOG

echo -ne Installing Dependencies...
apt-get install wget gnupg2 curl software-properties-common dirmngr apt-transport-https lsb-release ca-certificates -y >> $LOG
sleep 1
echo Done

echo -e

echo -e Installing Grafana..
curl https://packages.grafana.com/gpg.key |  apt-key add -  >> $LOG
add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"  >> $LOG
apt-get update  >> $LOG
apt-get -y install grafana  >> $LOG
systemctl enable grafana-server  >> $LOG
sleep 1
echo Done
clear

echo -ne Starting Grafana...
systemctl start grafana-server  >> $LOG
sleep 1
echo Done

echo -e

echo -e Grafana is $(systemctl status grafana-server| grep "Active:" | awk '{print $3}')
sleep 1

echo -ne Installing Prometheus...

echo -e

echo -ne Creating Prometheus User...
groupadd --system prometheus  >> $LOG
useradd -s /sbin/nologin --system -g prometheus prometheus  >> $LOG
mkdir /var/lib/prometheus  >> $LOG
sleep 1
echo Done

echo -e

echo -ne Creating structure...
for i in rules rules.d files_sd; do  mkdir -p /etc/prometheus/${i}; done  >> $LOG
mkdir -p /tmp/prometheus && cd /tmp/prometheus  >> $LOG
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest|grep browser_download_url|grep linux-amd64|cut -d '"' -f 4|wget -qi -  >> $LOG
tar xvf prometheus*.tar.gz  >> $LOG
cd prometheus*/  >> $LOG
mv prometheus promtool /usr/local/bin/  >> $LOG
mv prometheus.yml  /etc/prometheus/prometheus.yml  >> $LOG
mv consoles/ console_libraries/ /etc/prometheus/  >> $LOG
cd ~/  >> $LOG
rm -rf /tmp/prometheus >> $LOG
cat /etc/prometheus/prometheus.yml  >> $LOG
for i in rules rules.d files_sd; do  chown -R prometheus:prometheus /etc/prometheus/${i}; done  >> $LOG
for i in rules rules.d files_sd; do  chmod -R 775 /etc/prometheus/${i}; done  >> $LOG
chown -R prometheus:prometheus /var/lib/prometheus/  >> $LOG
sleep 1
echo Done

echo -e

echo -ne Creating Prometheus Service...
tee /etc/systemd/system/prometheus.service<<EOF>> $LOG
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus   --config.file=/etc/prometheus/prometheus.yml   --storage.tsdb.path=/var/lib/prometheus   --web.console.templates=/etc/prometheus/consoles   --web.console.libraries=/etc/prometheus/console_libraries   --web.listen-address=0.0.0.0:9090   --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sleep 1
echo Done

systemctl daemon-reload  >> $LOG
systemctl enable prometheus  >> $LOG
clear

echo -ne Starting Prometheus Service...
systemctl start prometheus  >> $LOG
sleep 1
echo Done

echo -e

echo -e Prometheus is $(systemctl status prometheus | grep "Active:" | awk '{print $3}')
sleep 1
clear

echo -e

echo -e Installing the Apache and MariaDB exporters

echo -e

echo -ne Downloading files...
curl -s https://api.github.com/repos/Lusitaniae/apache_exporter/releases/latest|grep browser_download_url|grep linux-amd64|cut -d '"' -f 4|wget -qi - >> $LOG
tar xvf apache_exporter-*.linux-amd64.tar.gz >> $LOG
cp apache_exporter-*.linux-amd64/apache_exporter /usr/local/bin >> $LOG
chmod +x /usr/local/bin/apache_exporter >> $LOG
sleep 1 
echo Done

echo -e

echo -ne Creating Apache Exporter Service...
tee /etc/systemd/system/apache_exporter.service<<EOF>> $LOG
[Unit]
Description=Prometheus
Documentation=https://github.com/Lusitaniae/apache_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/apache_exporter \
  --insecure \
  --scrape_uri=http://localhost/server-status/?auto \
  --telemetry.address=0.0.0.0:9117 \
  --telemetry.endpoint=/metrics

SyslogIdentifier=apache_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sleep 1
echo Done

systemctl daemon-reload >> $LOG
systemctl enable apache_exporter.service >> $LOG
clear

echo -ne Starting Apache Exporter Service...
systemctl start apache_exporter.service >> $LOG
sleep 1 
echo Done

echo -e

echo -e Apache Exporter is $(systemctl status apache_exporter.service  | grep "Active:" | awk '{print $3}')
sleep 1
clear

echo -e

echo -ne Updating Prometheus Config File...
mv /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.BAK 
cd /etc/prometheus/
wget https://raw.githubusercontent.com/alexoslabs2/udemy/main/Monitoramento/scripts/config/prometheus.yml  >> $LOG
sleep 1
echo Done

echo -e

echo -ne Restarting Prometheus Service...
systemctl restart prometheus >> $LOG
sleep 1
echo Done

echo -e

echo -e Prometheus is $(systemctl status prometheus | grep "Active:" | awk '{print $3}')
sleep 1
clear

echo -ne Installing MySQL Exporter...
curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest   | grep browser_download_url   | grep linux-amd64 | cut -d '"' -f 4   | wget -qi - >> $LOG
tar xvf mysqld_exporter*.tar.gz  >> $LOG
mv  mysqld_exporter-*.linux-amd64/mysqld_exporter /usr/local/bin/
chmod +x /usr/local/bin/mysqld_exporter
sleep 1
echo Done

echo -e

echo -ne Creating MySQL Exporter User in Database...
mysql -u root -p$DB_PASSWORD -e "CREATE USER 'mysqld_exporter'@'localhost' IDENTIFIED BY '$DB_PASSWORD' WITH MAX_USER_CONNECTIONS 2;"
mysql -u root -p$DB_PASSWORD -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'mysqld_exporter'@'localhost';FLUSH PRIVILEGES;"
sleep 1
echo Done

echo -e

echo -ne Creating MySQL Exporter Config File...
tee /etc/.mysqld_exporter.cnf<<EOF>> $LOG
[client]
user=mysqld_exporter
password=$DB_PASSWORD
EOF
chown root:prometheus /etc/.mysqld_exporter.cnf
sleep 1
echo Done

echo -e

echo -ne Creating MySQL Exporter Service...
tee /etc/systemd/system/mysql_exporter.service<<EOF>> $LOG
[Unit]
Description=Prometheus MySQL Exporter
After=network.target
User=prometheus
Group=prometheus

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mysqld_exporter \
--config.my-cnf /etc/.mysqld_exporter.cnf \
--collect.global_status \
--collect.info_schema.innodb_metrics \
--collect.auto_increment.columns \
--collect.info_schema.processlist \
--collect.binlog_size \
--collect.info_schema.tablestats \
--collect.global_variables \
--collect.info_schema.query_response_time \
--collect.info_schema.userstats \
--collect.info_schema.tables \
--collect.perf_schema.tablelocks \
--collect.perf_schema.file_events \
--collect.perf_schema.eventswaits \
--collect.perf_schema.indexiowaits \
--collect.perf_schema.tableiowaits \
--collect.slave_status \
--web.listen-address=127.0.0.1:9104

[Install]
WantedBy=multi-user.target
EOF
sleep 1
echo Done

systemctl daemon-reload >> $LOG
systemctl enable mysql_exporter >> $LOG
clear

echo -ne Starting MySQL Exporter...
systemctl start mysql_exporter >> $LOG
sleep 1
echo Done

echo -e

echo -e Apache Exporter is $(systemctl status mysql_exporter.service  | grep "Active:" | awk '{print $3}')
sleep 1
clear

# Infos
echo -e "== Access Information =="

echo -e

echo -e Grafana
echo URL: https://$(hostname -I)
echo Port: 3000
echo user: admin
echo password: admin

echo -e

echo -e "Warning: Change the password"

echo -e

echo -e Prometheus
echo URL: https://$(hostname -I)
echo Port: 9090
