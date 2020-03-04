yum -y install java java-devel git
useradd -d /opt/kafka -M -r kafka
pushd /opt
curl http://it.apache.contactlab.it/kafka/{{ kafka_version }}/kafka_2.13-{{ kafka_version }}.tgz | tar xvz
ln -sf kafka_2.13-{{ kafka_version }}/ kafka
chown -R kafka:kafka kafka kafka_2.13-{{ kafka_version }}
git clone https://github.com/linkedin/cruise-control.git
pushd ./cruise-control
./gradlew jar
./gradlew jar copyDependantLibs
sed -i '/^bootstrap.servers/s/=.*/={{ ["k0{}.{}:9092".format(node + 1, domain) for node in range(0, nodes)] | join(",") }}/' config/cruisecontrol.properties
sed -i '/^zookeeper.connect/s/=.*/={{ ["k0{}.{}:2181".format(node + 1, domain) for node in range(0, nodes)] | join(",") }}/' config/cruisecontrol.properties
sed -i '/^webserver.http.cors.enabled/s/=.*/=true/' config/cruisecontrol.properties
sed -i '/^webserver.http.cors.origin/s/=.*/=*/' config/cruisecontrol.properties
curl -L https://github.com/linkedin/cruise-control-ui/releases/download/v{{ cruise_version}}/cruise-control-ui-{{ cruise_version }}.tar.gz | tar xvz
popd
chown -R kafka:kafka ./cruise-control
popd
#systemctl daemon-reload
#systemctl enable --now cruise-control
