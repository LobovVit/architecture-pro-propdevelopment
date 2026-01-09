# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. secrets_access
   - Кто: system:apiserver
   - Где: secrets
   - Verb: list, URI: /api/v1/secrets?limit=500&resourceVersion=0

2. secrets_access
   - Кто: system:apiserver
   - Где: secrets
   - Verb: list, URI: /api/v1/secrets?limit=500&resourceVersion=0

3. audit_policy_tamper
   - Кто: system:node:minikube
   - Где: pods ns=kube-system name=kube-apiserver-minikube
   - Verb: create, URI: /api/v1/namespaces/kube-system/pods

4. audit_policy_tamper
   - Кто: system:node:minikube
   - Где: pods ns=kube-system name=kube-apiserver-minikube
   - Verb: create, URI: /api/v1/namespaces/kube-system/pods

5. audit_policy_tamper
   - Кто: system:node:minikube
   - Где: pods ns=kube-system name=kube-apiserver-minikube
   - Verb: create, URI: /api/v1/namespaces/kube-system/pods

6. audit_policy_tamper
   - Кто: system:node:minikube
   - Где: pods ns=kube-system name=kube-apiserver-minikube
   - Verb: get, URI: /api/v1/namespaces/kube-system/pods/kube-apiserver-minikube

7. audit_policy_tamper
   - Кто: system:node:minikube
   - Где: pods ns=kube-system name=kube-apiserver-minikube
   - Verb: get, URI: /api/v1/namespaces/kube-system/pods/kube-apiserver-minikube

8. audit_policy_tamper
   - Кто: system:node:minikube
   - Где: pods ns=kube-system name=kube-apiserver-minikube
   - Verb: get, URI: /api/v1/namespaces/kube-system/pods/kube-apiserver-minikube

9. secrets_access
   - Кто: system:serviceaccount:kube-system:namespace-controller
   - Где: secrets ns=audit-test
   - Verb: list, URI: /api/v1/namespaces/audit-test/secrets

10. secrets_access
   - Кто: system:serviceaccount:kube-system:namespace-controller
   - Где: secrets ns=audit-test
   - Verb: list, URI: /api/v1/namespaces/audit-test/secrets

## Вывод

События выше требуют ручной валидации: подтверждения контекста, источника учётки и легитимности действий. На практике такие паттерны (доступ к secrets, exec в kube-system, privileged pod, выдача cluster-admin) являются сильными индикаторами компрометации или ошибочной настройки RBAC.
