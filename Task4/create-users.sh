#!/usr/bin/env bash
set -e

# Создание пользователей Kubernetes через client certificates (Minikube)

OUT_DIR="./pki"
CLUSTER_NAME="minikube"

mkdir -p "$OUT_DIR"

CA_CERT="$HOME/.minikube/ca.crt"
CA_KEY="$HOME/.minikube/ca.key"

create_user () {
  USER=$1
  GROUP=$2

  openssl genrsa -out "$OUT_DIR/$USER.key" 2048
  openssl req -new -key "$OUT_DIR/$USER.key" \
    -out "$OUT_DIR/$USER.csr" \
    -subj "/CN=$USER/O=$GROUP"

  openssl x509 -req \
    -in "$OUT_DIR/$USER.csr" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$OUT_DIR/$USER.crt" \
    -days 365

  kubectl config set-credentials "$USER" \
    --client-certificate="$OUT_DIR/$USER.crt" \
    --client-key="$OUT_DIR/$USER.key" \
    --embed-certs=true

  kubectl config set-context "$USER@$CLUSTER_NAME" \
    --cluster="$CLUSTER_NAME" \
    --user="$USER"
}

create_user alice-viewer pd:viewers
create_user bob-operator pd:tenant-operators
create_user carol-devops pd:devops
create_user dave-security pd:security

echo "Users created:"
echo " - alice-viewer"
echo " - bob-operator"
echo " - carol-devops"
echo " - dave-security"