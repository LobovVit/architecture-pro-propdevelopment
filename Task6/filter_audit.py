#!/usr/bin/env python3
import json, sys, re, argparse
from datetime import datetime

SUSPICIOUS = []

def load_lines(path):
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line=line.strip()
            if not line:
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                # audit can contain partial lines; ignore
                continue

def is_priv_pod(ev):
    ro = ev.get("requestObject") or {}
    spec = ro.get("spec") or {}
    containers = spec.get("containers") or []
    for c in containers:
        sc = (c.get("securityContext") or {})
        if sc.get("privileged") is True:
            return True
    return False

def match(ev):
    verb = ev.get("verb")
    obj = ev.get("objectRef") or {}
    resource = obj.get("resource")
    subresource = obj.get("subresource")
    uri = ev.get("requestURI","")
    username = (ev.get("user") or {}).get("username","")
    # 1) secrets get/list
    if resource == "secrets" and verb in ("get","list"):
        return "secrets_access"
    # 2) exec
    if verb == "create" and subresource == "exec":
        return "pod_exec"
    # 3) privileged pod create/apply
    if resource == "pods" and verb in ("create","patch","update") and is_priv_pod(ev):
        return "privileged_pod"
    # 4) cluster-admin rolebinding
    if resource in ("rolebindings","clusterrolebindings") and verb in ("create","patch","update"):
        ro = ev.get("requestObject") or {}
        rr = ro.get("roleRef") or {}
        if rr.get("name") == "cluster-admin":
            return "cluster_admin_binding"
    # 5) audit-policy tampering (best-effort)
    if "audit-policy" in uri.lower() or "audit-policy" in str(ev).lower():
        # we don't want to match everything; keep as a separate tag
        return "audit_policy_tamper"
    return None

def who(ev):
    u = ev.get("user") or {}
    return u.get("username","unknown")

def where(ev):
    obj = ev.get("objectRef") or {}
    ns = obj.get("namespace","")
    name = obj.get("name","")
    res = obj.get("resource","")
    sub = obj.get("subresource","")
    loc = f"{res}"
    if sub:
        loc += f"/{sub}"
    if ns:
        loc += f" ns={ns}"
    if name:
        loc += f" name={name}"
    return loc.strip()

def summarize(events):
    lines = ["# Отчёт по результатам анализа Kubernetes Audit Log", "", "## Подозрительные события", ""]
    i=1
    for ev in events:
        tag = ev.get("_tag","event")
        lines.append(f"{i}. {tag}")
        lines.append(f"   - Кто: {who(ev)}")
        lines.append(f"   - Где: {where(ev)}")
        lines.append(f"   - Verb: {ev.get('verb')}, URI: {ev.get('requestURI','')}")
        lines.append("")
        i+=1
    if not events:
        lines += ["Не найдено событий по заданным эвристикам (проверьте, что audit включён и лог не пуст).", ""]
    lines += ["## Вывод", "", "События выше требуют ручной валидации: подтверждения контекста, источника учётки и легитимности действий. "
              "На практике такие паттерны (доступ к secrets, exec в kube-system, privileged pod, выдача cluster-admin) являются сильными индикаторами компрометации или ошибочной настройки RBAC.", ""]
    return "\n".join(lines)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", default="/var/log/audit.log", help="Path to audit log (JSON lines)")
    ap.add_argument("--out-json", default="audit-extract.json")
    ap.add_argument("--out-md", default="analysis.md")
    ap.add_argument("--limit", type=int, default=2000)
    args = ap.parse_args()

    out=[]
    for ev in load_lines(args.log):
        tag = match(ev)
        if tag:
            ev["_tag"]=tag
            out.append(ev)
            if len(out) >= args.limit:
                break

    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

    with open(args.out_md, "w", encoding="utf-8") as f:
        f.write(summarize(out))

    print(f"Wrote {len(out)} events to {args.out_json} and report to {args.out_md}")

if __name__ == "__main__":
    main()
