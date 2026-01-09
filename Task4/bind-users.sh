#!/usr/bin/env bash
set -e

# Viewer
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: alice-viewer-binding
subjects:
- kind: User
  name: alice-viewer
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pd:viewers
  apiGroup: rbac.authorization.k8s.io
EOF

# Namespace operator (tenant)
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: bob-operator-binding
  namespace: tenant
subjects:
- kind: User
  name: bob-operator
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pd:namespace-operator
  apiGroup: rbac.authorization.k8s.io
EOF

# Platform admin
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: carol-devops-binding
subjects:
- kind: User
  name: carol-devops
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pd:platform-admin
  apiGroup: rbac.authorization.k8s.io
EOF

# Security auditor
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dave-security-binding
subjects:
- kind: User
  name: dave-security
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pd:security-auditor
  apiGroup: rbac.authorization.k8s.io
EOF