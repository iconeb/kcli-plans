yum -y install java java-devel nmap-ncat git
useradd -d /opt/kafka -M -r kafka
pushd /opt
curl http://it.apache.contactlab.it/kafka/{{ kafka_version }}/kafka_2.13-{{ kafka_version }}.tgz | tar xvz
ln -sf kafka_2.13-{{ kafka_version }}/ kafka
chown -R kafka:kafka kafka kafka_2.13-{{ kafka_version }}
cat >> kafka/config/zookeeper.properties <<'EOF'
timeTick=2000
initLimit=10
syncLimit=5
4lw.commands.whitelist=*
{% for node in range(0, nodes) -%}
server.{{ node + 1 }}=k0{{ node + 1 }}.{{ domain }}:2888:3888
{%- endfor %}
EOF
popd
install -d -o kafka -g kafka /tmp/zookeeper
echo "${HOSTNAME: -1}" > /tmp/zookeeper/myid
sed -i '/^broker.id/s/0/'${HOSTNAME: -1}'/' /opt/kafka/config/server.properties
sed -i '/^zookeeper.connect/s/=.*/={{ ["k0{}.{}".format(node + 1, domain) for node in range(0, nodes)] | join(",") }}/' /opt/kafka/config/server.properties
cat >> /opt/kafka/config/server.properties <<'EOF'
listeners=REPLICATION://:9091,PLAINTEXT://:9092
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL,REPLICATION:PLAINTEXT
inter.broker.listener.name=REPLICATION
EOF
pushd /opt
git clone https://github.com/linkedin/cruise-control.git
pushd ./cruise-control
./gradlew jar
cp ./cruise-control-metrics-reporter/build/libs/cruise-control-metrics-reporter-*.jar /opt/kafka/libs/
chown kafka:kafka /opt/kafka/libs/cruise-control-metrics-reporter-*
echo "metrics.reporter=com.linkedin.kafka.cruisecontrol.metricsreporter.CruiseControlMetricsReporter" >> /opt/kafka/config/server.properties
popd
popd
#systemctl daemon-reload
#systemctl enable --now kafka-zookeeper.service
#systemctl enable --now kafka.service
