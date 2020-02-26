# prometheus-operator-configs

Custom configurations the Prometheus Operator, spanning Prometheus, AlertManager, and Grafana. In active early development, primarily on the development cluster. 

**Ready** 
- Figured out how to apply rules
- Figured out how to apply configurations
- AlertManager sending alerts to Slack (currently all dev cluster criticals to Cloud Slack #prometheus-alerts)
- Slack alerts formatted for readability and useful detail
- Tagged originating cluster to alerts (requires modifying the Prometheus Operator terraform script)
- Multi-cluster Grafana (requires modifying the Prometheus Operator terraform script)
- Slack alert silence, timestamps, grouping
- Elasticsearch exporter and rules - one per cluster

**In Progress**
- Elasticsearch exporter and rules - multi-namespace
- GPU metrics for DAaaS
- Exploring Grafana dashboards

**Upcoming**
- Blackbox exporter ([& eventual refactor to upcoming BlackboxMonitor](https://github.com/coreos/prometheus-operator/pull/2832))
- Port to other clusters
- Other useful exporters? (likely cluster-specific)
- Pipeline/refactor?

The code snippets in the following notes are listed for reference and may later be pipelined or refactored. Note that they do not have any -n flags: [kubens](https://github.com/ahmetb/kubectx) has been used to automaticaly enforce the 'monitoring' namespace on kubectl.

**To apply the cluster tag**, in the Prometheus Operator terraform script under prometheus.prometheusSpec, add: 

```
externalLabels:
  cluster: your cluster name
```

externalLabels should be flush with storageSpec.

An example usecase for this is to differentiate multiple clusters' AlertManagers alerting to the same Slack channel.

**To add more data sources to Grafana**, such as the Prometheus of other clusters, in the Prometheus Operator terraform script under grafana and flush with 'ingress', add (example):

```
additionalDataSources:
    - name: Dev-Prometheus
      type: prometheus
      url: https://prometheus.dev.cloud.statcan.ca
      access: proxy
    - name: ...and so on...
```

Other kinds of data sources [may have additional properties, such as credentials](https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources). 

Presently, I have had some issues with having the relevant helm changes recognized when going through the Prometheus Operator terraform script pipelines. They have been pushed through with local terraform scripts and additional inconsequential changes. [This may be an issue with helm version 2.13.1](https://github.com/helm/helm/issues/5915).

The data source changes are not applied automatically, but follow a reset through `kubectl scale deploy prometheus-operator-grafana --replicas=0` and `kubectl scale deploy prometheus-operator-grafana --replicas=1`. If an automatic workaround for this is needed, timestamp pod annotations are one option - [see the last comments here](https://github.com/coreos/prometheus-operator/issues/1909).

**To apply Prometheus rules**: `kubectl apply -f alert-tests.yaml` (or as many similar yamls as desired; they are picked up automatically as long as they are defined as a PrometheusRule and as corresponding to the appropriate namespace)

**To apply AlertManager configuration**:

```
kubectl create secret generic alertmanager-prometheus-operator-alertmanager \
--from-literal=alertmanager.yaml="$(helm template ./alertmanager-config -f alertmanager-config-overrides.yaml | awk '{if(NR>1)print}')" \
--from-file=alertmanager-tmpl/slackcustom.tmpl --dry-run -o yaml | kubectl apply -f -
```

alertmanager-config-overrides.yaml above is gitignored and intended for personalized private elements such as API keys.

The Prometheus Operator Alertmanager expects its configuarion as a base64 encoded secret (and "tmpl" template files used within the configuration are additional secrets). This makes it difficult to have those configurations themselves reference private variables. In order to allow the configuration to be shared publically and easily personalized, Helm templating is used to override private variables with private values. (To do: confirm how this works in the context of a pipeline)

Creating a dry run of a secret and then applying it updates the existing secret without running afoul of internal versioning, and without having to manually encode the contents.

The output of a helm template command begins with a first line of "---". This breaks applying, so awk is used to remove it.


Diverging from Helm chart best practices, the alertmanager.yaml template contains most of its values instead of those values being defined in values.yaml. This is due to two present helm template YAML issues: 

1. A lot is defined in lists, and lists get overriden completely instead of partially (i.e. the entire nest is required)
2. Retrieved URLS lose the quotes around them in a way that cannot be escaped, and the result cannot be parsed. If the URL is inside of a list, the quotes cannot be easily added after the fact: as per (1), the entire list is pulled in at once.

(Low-priority to do: link relevant issues)