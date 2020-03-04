yum -y install epel-release docker
systemctl enable --now docker
yum -y install jq
yum -y update
setenforce 0
sed -i '/^SELINUX/s/enforcing/permissive/' /etc/selinux/config
docker run -d -p 80:80 -p 443:443 --name rancher-server rancher/rancher:{{ rancher_version }}
while ! curl -k https://localhost/ping; do sleep 3; done

CURL="curl --insecure -H 'content-type: application/json'"
# Login
logintoken=$($CURL -s 'https://127.0.0.1/v3-public/localProviders/local?action=login' --data-binary '{"username":"admin","password":"admin"}' | jq -r .token)
# Change password
$CURL -s 'https://127.0.0.1/v3/users?action=changepassword' -H "Authorization: Bearer $logintoken" --data-binary '{"currentPassword":"admin","newPassword":"{{ admin_password }}"}'

# Create API key
apitoken=$($CURL -s 'https://127.0.0.1/v3/token' -H "Authorization: Bearer $logintoken" --data-binary '{"type":"token","description":"automation"}' | jq -r .token)

# Set server-url
$CURL -s 'https://127.0.0.1/v3/settings/server-url' -H "Authorization: Bearer $apitoken" -X PUT --data-binary '{"name":"server-url","value":"'$(hostname -f)'"}' > /dev/null

# Create cluster
clusterid=$($CURL -s 'https://127.0.0.1/v3/cluster' -H "Authorization: Bearer $apitoken" --data-binary '{"dockerRootDir":"/var/lib/docker","enableNetworkPolicy":false,"type":"cluster","rancherKubernetesEngineConfig":{"addonJobTimeout":30,"ignoreDockerVersion":true,"sshAgentAuth":false,"type":"rancherKubernetesEngineConfig","authentication":{"type":"authnConfig","strategy":"x509"},"network":{"type":"networkConfig","plugin":"canal"},"ingress":{"type":"ingressConfig","provider":"nginx"},"monitoring":{"type":"monitoringConfig","provider":"metrics-server"},"services":{"type":"rkeConfigServices","kubeApi":{"podSecurityPolicy":false,"type":"kubeAPIService"},"etcd":{"snapshot":false,"type":"etcdService","extraArgs":{"heartbeat-interval":500,"election-timeout":5000}}}},"name":"mycluster"}' | jq -r .id)

# Create token
$CURL -s 'https://127.0.0.1/v3/clusterregistrationtoken' -H "Authorization: Bearer $apitoken" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$clusterid'"}' > /dev/null

# Set role flags
roleflags="--etcd --controlplane --worker"

# Generate nodecommand
agentcmd=$($CURL -s 'https://127.0.0.1/v3/clusterregistrationtoken?id="'$clusterid'"' -H "Authorization: Bearer $apitoken" | jq -r '.data[].nodeCommand' | head -1)

# Concat commands
dockercmd="$agentcmd $roleflags"

# Execute command
$dockercmd
