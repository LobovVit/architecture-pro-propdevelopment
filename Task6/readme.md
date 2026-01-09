# Включение Kubernetes Audit Log в Minikube

## Цель

Включить **Audit Logging** в `kube-apiserver` Minikube 

---

## Окружение

- OS: Ubuntu 22.04
- Minikube driver: docker
- Kubernetes: ≥ 1.24
- `kubectl` настроен и работает
- Доступ к `sudo`

---

## Шаг 0. Проверка Minikube (на хосте)

### полностью удалить существующий
```bash
minikube delete --all --purge
docker ps -a | grep minikube && docker system prune -a -f
rm -rf ~/.minikube ~/.kube
```
### запустить без аудита для начала
```minikube start --driver=docker```
### проверить
```bash
minikube status
kubectl get nodes
```

---

## Шаг 1. Подключение в ноду Minikube

```bash
minikube ssh
```

Дальше **все команды выполняются внутри**:
```
docker@minikube:~$
```

---

## Шаг 2. Подготовка директорий

```bash
sudo mkdir -p /var/lib/minikube/manifests-backup
sudo mkdir -p /etc/kubernetes/audit
```

---

## Шаг 3. Сохранение «золотого» бэкапа kube-apiserver

⚠️ Бэкап **НЕ ДОЛЖЕН** лежать в `/etc/kubernetes/manifests`

```bash
sudo cp -f \
  /etc/kubernetes/manifests/kube-apiserver.yaml \
  /var/lib/minikube/manifests-backup/kube-apiserver.yaml.orig
```

---

## Шаг 4. Создание Audit Policy и лог-файла

```bash
sudo tee /etc/kubernetes/audit/audit-policy.yaml >/dev/null <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: RequestResponse
    verbs: ["create", "delete", "update", "patch", "get", "list"]
    resources:
      - group: ""
        resources: ["pods", "secrets", "configmaps", "serviceaccounts"]
      - group: "rbac.authorization.k8s.io"
        resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  - level: Metadata
    omitStages:
      - RequestReceived
EOF

sudo touch /etc/kubernetes/audit/audit.log
sudo chmod 600 /etc/kubernetes/audit/audit.log
```

Проверка:

```bash
ls -la /etc/kubernetes/audit
```

---

## Шаг 5.  скрипт включения Audit

Создать файл:

```bash
cat > /tmp/enable-audit-rocksolid.sh <<'EOS'
#!/usr/bin/env bash
set -euo pipefail

F=/etc/kubernetes/manifests/kube-apiserver.yaml
MDIR=/etc/kubernetes/manifests
BKDIR=/var/lib/minikube/manifests-backup

AUD_DIR=/etc/kubernetes/audit
POLICY=${AUD_DIR}/audit-policy.yaml
ALOG=${AUD_DIR}/audit.log

# 0. Убираем любые лишние kube-apiserver.yaml.* из manifests
find "$MDIR" -maxdepth 1 -type f -name 'kube-apiserver.yaml.*' -print 2>/dev/null \
  | while read -r p; do
      mv -f "$p" "$BKDIR/$(basename "$p")"
    done

# 1. Восстанавливаем чистый манифест
cp -f "$BKDIR/kube-apiserver.yaml.orig" "$F"

# 2. Добавляем audit-флаги
sed -i '/--secure-port=/a\
    - --audit-log-path=/etc/kubernetes/audit/audit.log\
    - --audit-log-maxage=30\
    - --audit-log-maxbackup=10\
    - --audit-log-maxsize=100\
    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml' "$F"

# 3. Добавляем volumeMount
sed -i '/volumeMounts:/a\
    - mountPath: /etc/kubernetes/audit\
      name: audit-dir' "$F"

# 4. Добавляем volume
sed -i '/volumes:/a\
  - name: audit-dir\
    hostPath:\
      path: /etc/kubernetes/audit\
      type: DirectoryOrCreate' "$F"

# 5. Перезапуск kubelet
systemctl restart kubelet
EOS
```

Запуск:

```bash
sudo bash /tmp/enable-audit-rocksolid.sh
```

---

## Шаг 6. Проверка, что kube-apiserver запущен с audit

```bash
CID=$(sudo crictl ps -a --name kube-apiserver -q | head -n1)
PID=$(sudo crictl inspect "$CID" | sed -n 's/.*"pid": *\([0-9]*\).*/\1/p' | head -n1)

sudo tr '\0' '\n' < /proc/$PID/cmdline | grep -- '--audit'
```

Ожидаемо — список `--audit-*` флагов.

---

## Шаг 7. Генерация audit-событий (на хосте)

```bash
kubectl create ns audit-test
kubectl delete ns audit-test
```

---

## Шаг 8. Проверка audit-лога (в ноде)

```bash
sudo tail -n 50 /etc/kubernetes/audit/audit.log
```

---

---

---

## Готово
Audit Logging включён.
## Быстрое восстановление (если что-то пошло не так)
```bash
sudo cp -f /var/lib/minikube/manifests-backup/kube-apiserver.yaml.orig \
  /etc/kubernetes/manifests/kube-apiserver.yaml
sudo systemctl restart kubelet
```
---

---

---


## Шаг 9 Запуск симуляции инцидента

На хосте:
```bash
bash simulate-incident.sh
```

---

## Шаг 10 Сформировать артефакты

Артефакты должны быть в директории `Task6/`:
- `analysis.md`
- `audit-extract.json`
- `filter_audit.py`

### 10.1 Запустить фильтрацию (на ноде)

Скопируйте папку Task6 на ноду:
```bash
minikube cp Task6 /tmp/Task6
```

Запустите:
```bash
minikube ssh -- "cd /tmp/Task6 && python3 ./filter_audit.py --log /var/log/audit.log --out-json audit-extract.json --out-md analysis.md"
```

### 10.2 Забрать готовые файлы на хост

```bash
minikube cp /tmp/Task6 ./Task6
ls -la ./Task6
```

---

---

## Результат

В `Task6/` должно быть **ровно 3 файла**:
- `analysis.md`
- `audit-extract.json`
- `filter_audit.py`

