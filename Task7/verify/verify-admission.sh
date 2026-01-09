#!/usr/bin/env bash
set -euo pipefail

echo "== Verify PodSecurity & Gatekeeper admission =="

# абсолютные пути относительно самого скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

NS="audit-zone"
INSEC_DIR="$ROOT_DIR/insecure-manifests"
SEC_DIR="$ROOT_DIR/secure-manifests"

echo
echo "[0] Preflight"
echo "ROOT_DIR=$ROOT_DIR"
echo "INSEC_DIR=$INSEC_DIR"
echo "SEC_DIR=$SEC_DIR"
echo "Namespace=$NS"

# чтобы *.yaml превращалось в пустой список, а не в литерал
shopt -s nullglob

insecure_files=("$INSEC_DIR"/*.yaml)
secure_files=("$SEC_DIR"/*.yaml)

if (( ${#insecure_files[@]} == 0 )); then
  echo "❌ No insecure manifests found in: $INSEC_DIR"
  exit 1
fi

if (( ${#secure_files[@]} == 0 )); then
  echo "❌ No secure manifests found in: $SEC_DIR"
  exit 1
fi

echo
echo "[1] Проверка: небезопасные манифесты должны быть ОТКЛОНЕНЫ"

for f in "${insecure_files[@]}"; do
  echo "- Applying $f"
  set +e
  out="$(kubectl apply -f "$f" 2>&1)"
  rc=$?
  set -e

  if (( rc != 0 )); then
    echo "  ✅ blocked as expected"
    echo "  --- reason (kubectl output) ---"
    echo "$out" | sed 's/^/  /'
    echo "  ------------------------------"
  else
    echo "  ❌ NOT blocked (applied successfully) — ERROR"
    echo "  --- kubectl output ---"
    echo "$out" | sed 's/^/  /'
    echo "  ----------------------"
    exit 1
  fi
done

echo
echo "[2] Проверка: безопасные манифесты должны быть ПРИНЯТЫ"

for f in "${secure_files[@]}"; do
  echo "- Applying $f"
  kubectl apply -f "$f"
done

echo
echo "[3] Проверка: поды действительно запущены"
kubectl get pods -n "$NS" -o wide

echo
echo "✅ Admission работает корректно"