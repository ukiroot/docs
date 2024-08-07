#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

wait_readiness_of_pod() {
   NAME_SPACE="$1"
   POD_NAME="$2"
   JSON_PATH="$3"

   while [[ `KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n ${NAME_SPACE} get pod -l component=${POD_NAME} --output jsonpath="${JSON_PATH}"` != "${POD_NAME}" ]]; do
      sleep 5
   done

   KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n ${NAME_SPACE} wait pod -l component=${POD_NAME} --for condition=Ready
}

precondition_known_issues () {

   echo 'Turn off selinux. Details by link:
   https://github.com/kubernetes/kubeadm/issues/279'
   setenforce 0
   sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

   echo 'Turn off swap. Details by link:
   https://github.com/kubernetes/kubeadm/issues/610
   '
   sed -i '/swap/d' /etc/fstab
   swapoff -a

   echo 'Enable "net.bridge.bridge-nf-call-ip6tables/net.bridge.bridge-nf-call-iptables" to avoid error:
    [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables contents are not set to 1
   Details: https://github.com/kubernetes/kubeadm/issues/1062
   '
   cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
   sysctl --system

   echo 'Turn off firewall. Configuration of firewall and debug network issue overhead in test environment'
   systemctl stop firewalld || true
   systemctl disable firewalld || true
}

step_1_install_requrements () {

   yum install -y yum-utils device-mapper-persistent-data lvm2
   yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   yum install -y docker-ce
   systemctl start docker
   systemctl enable docker
}

step_2_install_kuber () {
   cat > /etc/yum.repos.d/kubernetes.repo << "EOF"
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF
   yum install -y kubelet kubeadm
}

step_3_postinstall_issues() {
    echo 'Enable cri"
    https://github.com/flatcar/Flatcar/issues/283'
    
    sed -i 's/disabled_plugins = \["cri"\]/#disabled_plugins = \["cri"\]/' /etc/containerd/config.toml
    systemctl restart containerd
}

step_4_init_cluster() {
   kubeadm reset -f
   rm -rfv ~/.kube/
   rm -rfv /var/log/pods/*
   kubeadm init --v=5 --pod-network-cidr=10.244.0.0/16
   wait_readiness_of_pod "kube-system" "kube-apiserver" "{.items[0].metadata.labels.component}"
}

step_5_postinit_issues() {
   echo 'Without "kube-flannel.yml" conteiners hanged in "pending" state'
   KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

step_6_share_cluster_autorization_conf() {
   echo 'Share by http cluster autorization config. For test environment'
   yum install -y httpd
   rm -rf /var/www/html
   ln -s /etc/kubernetes/ /var/www/html
   cat > /etc/httpd/conf.d/welcome.conf << "EOF"
<LocationMatch "^/+$">
    Options +Indexes
</LocationMatch>
EOF
   systemctl start httpd
   systemctl enable httpd
   chmod o+r /etc/kubernetes/*
}

step_7_copy_autorization_config_to_home_dir() {
   mkdir -p $HOME/.kube
   cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   chown $(id -u):$(id -g) $HOME/.kube/config
}

step_8_masternoschedule() {
echo 'Issue masternoschedule.
Because test environment include only master node.
Details by link:
https://stackoverflow.com/questions/55191980/remove-node-role-kubernetes-io-masternoschedule-taint'

kubectl taint node `hostname` node-role.kubernetes.io/control-plane:NoSchedule-
}

step_9_install_kubernetes_dashboard() {
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
}

step_10_configure_kubernetes_dashboard() {
  echo 'Enable anonymous authorization'
  kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-skip-login"}]'
  echo 'Show all namespaces'
  kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts
}

step_11_dnat_and_masquerade_kubernetes_dashboard() {
   ETH0_ADDRESS=`ip -4 -o addr show eth0 | awk '{print $4}' | cut -d "/" -f 1`
   KUBE_DASHBOARD_NAMESPACE='kubernetes-dashboard'

   wait_readiness_of_pod "${KUBE_DASHBOARD_NAMESPACE}" "kubernetes-dashboard" "{.items[0].metadata.labels.k8s-app}"

   KUBE_DASHBOARD_POD_NAME=`kubectl -n ${KUBE_DASHBOARD_NAMESPACE} get pod -l k8s-app=kubernetes-dashboard --output jsonpath='{.items[0].metadata.name}'`
   KUBE_DASHBOARD_POD_IP=`kubectl -n ${KUBE_DASHBOARD_NAMESPACE} get pod "${KUBE_DASHBOARD_POD_NAME}" --output jsonpath='{.status.podIP}'`
   KUBE_DASHBOARD_POD_PORT=`kubectl -n ${KUBE_DASHBOARD_NAMESPACE} get pod "${KUBE_DASHBOARD_POD_NAME}" --output jsonpath='{.spec.containers[0].ports[0].containerPort}'`
   iptables -t nat -A PREROUTING -d "${ETH0_ADDRESS}/32" -i eth0 -p tcp -m multiport --dports "${KUBE_DASHBOARD_POD_PORT}" -j DNAT --to-destination "${KUBE_DASHBOARD_POD_IP}"
   iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
}

precondition_known_issues
step_1_install_requrements
step_2_install_kuber
step_3_postinstall_issues
step_4_init_cluster
step_5_postinit_issues
step_6_share_cluster_autorization_conf
step_7_copy_autorization_config_to_home_dir
step_8_masternoschedule
step_9_install_kubernetes_dashboard
step_10_configure_kubernetes_dashboard
step_11_dnat_and_masquerade_kubernetes_dashboard




#########
#########cat << EOF | kubectl apply -f -
#########kind: StorageClass
#########apiVersion: storage.k8s.io/v1
#########metadata:
#########  name: local-storage
#########provisioner: kubernetes.io/no-provisioner
#########volumeBindingMode: WaitForFirstConsumer
#########EOF
