#!/bin/bash

cd terraform
terraform init
terraform apply -auto-approve

INSTANCE_IP=$(terraform output -raw instance_public_ip)
echo "Instance Public IP: $INSTANCE_IP"

while ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i /home/harshal/Downloads/devops.pem ubuntu@$INSTANCE_IP exit; do
  echo "Waiting for SSH to be ready..."
  sleep 5
done

cd ..

ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl wait deployment cert-manager-webhook -n cert-manager --for=condition=Available --timeout=120s
kubectl wait --for=condition=complete --timeout=120s -n kube-system job/helm-install-traefik-crd
sleep 5


kubectl rollout status deployment/cert-manager -n cert-manager --timeout=120s
kubectl create namespace my-app || echo "Namespace 'my-app' already exists"
kubectl get ns simple-http || kubectl create namespace simple-http

kubectl apply -f /home/harshal/Tasks/k3s/k3s-automation/k3s/letsencrypt-prod.yaml
kubectl apply -f /home/harshal/Tasks/k3s/k3s-automation/k3s/traefik-https-redirect-middleware.yaml
kubectl apply -f /home/harshal/Tasks/k3s/k3s-automation/k3s/deploy.yaml

kubectl apply -f /home/harshal/Tasks/k3s/k3s-automation/k3s/letsencrypt-prod.yaml


kubectl get all -A
kubectl get pods -A
kubectl get svc -A
