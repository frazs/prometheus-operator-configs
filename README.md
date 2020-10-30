# prometheus-operator-configs

Custom configurations the Prometheus Operator, spanning Prometheus, AlertManager, Grafana, and various exporters. Work in progress.

The code snippets in the following notes are listed for reference and may later be pipelined or refactored. **Note that they do not include the -n flag**: on my end, [kubens](https://github.com/ahmetb/kubectx) is used to automaticaly enforce the 'monitoring' namespace on kubectl commands. 

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
kubectl create secret generic alertmanager-prometheus-operator-alertmanager --from-literal=alertmanager.yaml="$(helm template ./alertmanager-config -f alertmanager-config-overrides.yaml | awk '{if(NR>1)print}')" --from-file=alertmanager-tmpl/slackcustom.tmpl --from-file=alertmanager-tmpl/email.html --dry-run -o yaml | kubectl apply -f -
```

alertmanager-config-overrides.yaml above is gitignored and intended for personalized private elements such as API keys and SMTP credentials. Its keys must match [alertmanger-config/values.yaml](alertmanager-config/values.yaml) when those values are used.

The Prometheus Operator Alertmanager expects its configuarion as a base64 encoded secret (and "tmpl" template files used within the configuration are additional secrets). This makes it difficult to have those configurations themselves reference private variables. In order to allow the configuration to be shared publically and easily personalized, Helm templating is used to override private variables with private values. (To do: confirm how this works in the context of a pipeline)

Creating a dry run of a secret and then applying it updates the existing secret without running afoul of internal versioning, and without having to manually encode the contents.

The output of a helm template command begins with a first line of "---". This breaks applying, so awk is used to remove it.


Diverging from Helm chart best practices, the alertmanager.yaml template contains most of its values instead of those values being defined in values.yaml. This is due to two helm template YAML issues at the time of development: 

1. A lot is defined in lists, and lists get overriden completely instead of partially (i.e. the entire nest is required)
2. Retrieved URLS lose the quotes around them in a way that cannot be escaped, and the result cannot be parsed. If the URL is inside of a list, the quotes cannot be easily added after the fact: as per (1), the entire list is pulled in at once.

**To create or reconfigure a blackbox exporter**:
Refer to the [helm chart repo](https://github.com/helm/charts/tree/master/stable/prometheus-blackbox-exporter) and [sample configuration](blackbox-exporter/config.yaml). Note the labels for the Prometheus Operator to pick up the service. This will be deprecated after upgrading to Prometheus Operator 0.41 and replaced by Probe configurations. 
