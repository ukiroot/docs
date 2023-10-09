#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

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
   systemctl stop firewalld
   systemctl disable firewalld
}

step_1_install_requrements () {

   yum install -y yum-utils device-mapper-persistent-data lvm2
   yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
   yum install -y docker-ce
   systemctl start docker
   systemctl enable docker
}

step_2_install_kuber () {
   cat >> /etc/yum.repos.d/kubernetes.repo << "EOF"
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
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
}

step_5_share_cluster_autorization_conf() {
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

step_6_copy_autorization_config_to_home_dir() {
   mkdir -p $HOME/.kube
   cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   chown $(id -u):$(id -g) $HOME/.kube/config
}

step_7_masternoschedule() {
echo 'Issue masternoschedule.
Because test environment include only master node.
Details by link:
https://stackoverflow.com/questions/55191980/remove-node-role-kubernetes-io-masternoschedule-taint'

kubectl taint node `hostname` node-role.kubernetes.io/control-plane:NoSchedule-
}

step_8_install_kubernetes_dashboard() {
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
}

step_9_configure_kubernetes_dashboard() {
  echo 'Enable anonymous authorization'
  kubectl patch deployment kubernetes-dashboard -n kubernetes-dashboard --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-skip-login"}]'
  echo 'Show all namespaces'
  kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts
}

step_10_dnat_and_masquerade_kubernetes_dashboard() {
   ETH0_ADDRESS=`ip -4 -o addr show eth0 | awk '{print $4}' | cut -d "/" -f 1`
   KUBE_DASHBOARD_NAMESPACE='kubernetes-dashboard'
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
step_5_share_cluster_autorization_conf
step_6_copy_autorization_config_to_home_dir
step_7_masternoschedule
step_8_install_kubernetes_dashboard
step_9_configure_kubernetes_dashboard
step_10_dnat_and_masquerade_kubernetes_dashboard



#########kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
#########
#########cat << EOF | kubectl apply -f -
#########kind: StorageClass
#########apiVersion: storage.k8s.io/v1
#########metadata:
#########  name: local-storage
#########provisioner: kubernetes.io/no-provisioner
#########volumeBindingMode: WaitForFirstConsumer
#########EOF
