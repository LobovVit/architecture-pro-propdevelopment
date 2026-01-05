#!/usr/bin/env bash
set -e

# Создание namespace’ов
kubectl create namespace sales || true
kubectl create namespace tenant || true
kubectl create namespace finance || true
kubectl create namespace data || true
kubectl create namespace platform || true

# ClusterRole: read-only
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd:viewers
rules:
- apiGroups: ["", "apps", "batch", "networking.k8s.io"]
  resources: ["pods", "services", "deployments", "configmaps", "events", "pods/log"]
  verbs: ["get", "list", "watch"]
EOF

# Role: namespace operator (пример для tenant)
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pd:namespace-operator
  namespace: tenant
rules:
- apiGroups: ["", "apps", "batch", "networking.k8s.io"]
  resources:
    - pods
    - pods/log
    - pods/exec
    - services
    - deployments
    - configmaps
    - events
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# ClusterRole: platform admin
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd:platform-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF

# ClusterRole: security auditor
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pd:security-auditor
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps", "events"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  verbs: ["get", "list", "watch"]
EOF