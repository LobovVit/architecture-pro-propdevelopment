# Task7 — PodSecurity + OPA Gatekeeper

## Цель
- В `audit-zone` включить PodSecurity `restricted` и убедиться, что небезопасные поды блокируются.
- Поставить OPA Gatekeeper и включить ограничения:
  - privileged запрещён
  - hostPath запрещён
  - runAsNonRoot=true обязательно
  - readOnlyRootFilesystem=true обязательно
  - allowPrivilegeEscalation=false обязательно

---

## 1) Создать namespace `audit-zone` с PodSecurity restricted
```bash
kubectl apply -f 01-create-namespace.yaml
kubectl get ns audit-zone --show-labels
```

## 2) Проверить PodSecurity Admission (insecure должны отклониться)
```bash
# из директории Task7
bash verify/verify-admission.sh
```

## 3) Установить OPA Gatekeeper
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=180s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=180s
```

## 4) Применить Gatekeeper ConstraintTemplates + Constraints
```bash
kubectl apply -f gatekeeper/constraint-templates/
kubectl get constrainttemplates

kubectl apply -f gatekeeper/constraints/
kubectl get constraints
```

## 5) Проверить enforcement Gatekeeper
```bash
for f in insecure-manifests/*.yaml; do
  echo "== $f"
  kubectl apply -f "$f" || true
done

kubectl apply -f secure-manifests/
bash verify/validate-security.sh
```
