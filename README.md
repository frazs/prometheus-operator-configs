# prometheus-rules

For the Prometheus Operator: Custom Prometheus rules and AlertManager configurations. In active early development. 

**Ready** \
- Figured out how to apply rules
- Figured out how to apply configurations
- AlertManager sending alerts to Slack (currently all dev cluster criticals to Cloud Slack #prometheus-alerts)
- Slack alerts formatted for readability and useful detail
- Tagged originating cluster to alerts (requires modifying the Prometheus Operator terraform script)

**Upcoming** \
- Useful custom rules
- Grafana dashboards
- Pipelines
- Blackbox settings ([BlackboxMonitor ready soon](https://github.com/coreos/prometheus-operator/pull/2832)
- Port to other clusters
- Other useful exporters (likely cluster-specific, e.g. GPU metrics for DAaaS)


The following code snippets are listed for reference and will be pipelined. [kubens](https://github.com/ahmetb/kubectx) has been used to automaticaly apply them in the 'monitoring' namespace, so I'll need to double-check them with the appropriate -n flag placements. 

**To apply the cluster tag**, in the Prometheus Operator terraform script under prometheus.prometheusSpec, add: 

```
externalLabels:
  cluster: your cluster name
```

externalLabels should be flush with storageSpec.

An example usecase for this is to differentiate multiple clusters' AlertManagers alerting to the same Slack channel.

**To apply Prometheus rules**: `kubectl apply -f alert-tests.yaml` (or as many similar yamls as desired; they are picked up automatically as long as they are defined as a PrometheusRule and as corresponding to the appropriate namespace)

**To apply AlertManager configuration**:

```
kubectl create secret generic alertmanager-prometheus-operator-alertmanager --from-literal=alertmanager.yaml="$(helm template ./alertmanager-config -f alertmanager-config-overrides.yaml --dry-run | awk '{if(NR>1)print}')" --from-file=alertmanager-tmpl/slackcustom.tmpl --dry-run -o yaml | kubectl apply -f -
```

alertmanager-config-overrides.yaml above is gitignored and intended for personalized private elements such as API keys.

The Prometheus Operator Alertmanager expects its configuarion as a base64 encoded secret (and "tmpl" template files used within the configuration are additional secrets). This makes it difficult to have those configurations themselves reference private variables. In order to allow the configuration to be shared publically and easily personalized, Helm templating is used to override private variables with private values. (To do: confirm how this works in the context of a pipeline)

Creating a dry run of a secret and then applying it updates the existing secret without running afoul of internal versioning, and without having to manually encode the contents.

The output of a helm template command begins with a first line of "---". This breaks applying, so awk is used to remove it.


Diverging from Helm chart best practices, the alertmanager.yaml template contains most of its values instead of those values being defined in values.yaml. This is due to two present helm template YAML issues: 

1. A lot is defined in lists, and lists get overriden completely instead of partially (i.e. the entire nest is required)
2. URLs loses the quotes around them in a way that cannot be escaped, and the result cannot be parsed. If the URL is inside of a list, the quotes cannot be added after the fact: as per (1), the entire list is pulled in at once.

(Low-priority to do: link relevant issues)