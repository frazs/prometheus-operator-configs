# prometheus-rules

Custom rules for Prometheus and AlertManager configuration on the Prometheus Operator. In active early development.

**Current status**: AlertManager Slack alert design R&D.
**After**: New rules, blackbox, GPU metrics, Grafana.

Some quick notes, to be transformed into proper documentation soon:

- monitoring namespace
- prometheus rules in root yaml(s)
- AM config with helm templating, override private values (currently just slack webhook api)
```
    kubectl create secret generic alertmanager-prometheus-operator-alertmanager --from-literal=alertmanager.yaml="$(helm template ./alertmanager-config -f alertmanager-config-overrides.yaml --dry-run | awk '{if(NR>1)print}')" --dry-run -o yaml | kubectl apply -f -
```
- explain above (config as encoded secret, awked template output)
- diverging from helm best practice of template/values seperation due to two Yaml lists issues (lists must be overriden completely, lists retrieved via toYaml strip necessary URL quotes)