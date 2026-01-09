# Task 5 — Управление трафиком внутри кластера Kubernetes

В задании настроено разграничение сетевого трафика между pod’ами
внутри одного namespace Kubernetes с использованием NetworkPolicy.

## Цель
- Развернуть 4 сервиса (pod + service) на базе образа `nginx`
- Назначить сервисам роли с помощью labels
- Изолировать сетевой трафик между сервисами
- Разрешить взаимодействие **только между логически связанными парами**

Разрешённые пары:
- `front-end` ↔ `back-end-api`
- `admin-front-end` ↔ `admin-back-end-api`

Весь остальной трафик между pod’ами должен быть запрещён.

---

## Используемые роли сервисов

| Pod / Service | Label |
|--------------|-------|
| front-end-app | `role=front-end` |
| back-end-api-app | `role=back-end-api` |
| admin-front-end-app | `role=admin-front-end` |
| admin-back-end-api-app | `role=admin-back-end-api` |

---

## Развёртывание сервисов

Все сервисы разворачиваются в одном namespace.

```bash
kubectl create ns task5
kubectl config set-context --current --namespace=task5

kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80
```

---

## Применение сетевых политик
```bash
kubectl apply -f non-admin-api-allow.yaml
```
Политики выполняют следующие функции:
* включают default deny для ingress и egress
* разрешают трафик только внутри допустимых пар сервисов
* изолируют admin-сервисы от non-admin-сервисов

## Проверка доступности сервисов 
### Запуск тестового pod
```kubectl run test-$RANDOM --rm -i -t --image=alpine -- sh```
### должно работать
```bash
wget -qO- --timeout=2 http://front-end-app
wget -qO- --timeout=2 http://back-end-api-app
wget -qO- --timeout=2 http://admin-front-end-app
wget -qO- --timeout=2 http://admin-back-end-api-app
```
### не должно работать
```bash
wget -qO- --timeout=2 http://admin-back-end-api-app   
wget -qO- --timeout=2 http://back-end-api-app        
```
### Чтобы тестировать “из конкретной роли”, удобнее запускать тестовый pod с нужным label role=…
```bash
kubectl run test-fe --rm -i -t --image=alpine --labels role=front-end -- sh
```