# Task 4 — RBAC роли для Kubernetes (PropDevelopment)

Ниже — проектная ролевая модель доступа к кластеру Kubernetes, исходя из оргструктуры PropDevelopment
(домены + продуктовые команды, DevOps и один специалист по ИБ).

## Принятые допущения
- Каждый домен работает в своём namespace:
    - sales
    - tenant
    - finance
    - data
    - platform
- Доступ ограничивается namespace’ами и ролями.
- Прямого доступа партнёров в Kubernetes нет.

## Таблица ролей

| Роль | Полномочия | Группы пользователей |
|----|-----------|---------------------|
| **pd:viewers** (ClusterRole) | Только просмотр ресурсов кластера (`get/list/watch`) без доступа к Secret | Руководители продуктов, бизнес-аналитики, поддержка |
| **pd:namespace-operator** (Role) | Управление workload в своём namespace (deployments, pods, services, ingress), без Secret | Разработчики и инженеры эксплуатации доменов |
| **pd:platform-admin** (ClusterRole) | Настройка и администрирование кластера, namespaces, сетевые политики | DevOps-инженеры |
| **pd:security-auditor** (ClusterRole) | Просмотр Secret, RBAC и событий (audit) | Специалист по ИБ |