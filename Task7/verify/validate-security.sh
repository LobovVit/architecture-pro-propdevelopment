#!/usr/bin/env bash
set -euo pipefail

echo "== Validate PodSecurity + Gatekeeper presence =="

echo
echo "[1] Namespace labels:"
kubectl get ns audit-zone --show-labels

echo
echo "[2] PodSecurity Admission (server supports it by default on modern k8s)"
echo "Tip: check rejections in previous step output (Forbidden: violates PodSecurity restricted)"

echo
echo "[3] Gatekeeper components:"
if kubectl get ns gatekeeper-system >/dev/null 2>&1; then
  kubectl get pods -n gatekeeper-system
  echo
  echo "[4] Gatekeeper policies:"
  kubectl get constrainttemplates || true
  kubectl get constraints || true
else
  echo "gatekeeper-system namespace not found (Gatekeeper not installed)"
  exit 1
fi

echo
echo "✅ Basic checks passed"