#!/bin/bash
echo "#######################################################################################################"
echo "kubeadm init in the k8s master node"
echo "#######################################################################################################"

systemctl enable kubelet && systemctl start kubelet
kubeadm reset -f
kubeadm init --token abcdef.0123456789abcdef --v=5
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
