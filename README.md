# prometheus-operator-configs

A collection of example monitoring component configurations intended for use with the Prometheus Operator as installed through [Kube Prometheus-Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).

Provided on an as-is basis for reference. May be out of date.

## Notes

### Alert labels

The alert labels used in these examples, `severity`, `scope`, and `resolves` are all arbitrarily defined for the specific routing desired. They do not need to be used in this manner, with these names, or at all. 

The `resolves: never` label is used to handle not reporting resolutions for certain increment based alerts that, by design, always immediately resolve themselves. 

### To apply the cluster tag to alerts

In kube-prometheus-stack values, under `prometheus.prometheusSpec`, add: 

```
externalLabels:
  cluster: your cluster name
```

`externalLabels` should be flush with `storageSpec`.

An example usecase for this is to differentiate multiple clusters' Alertmanagers alerting to the same notification channel.

### To add more data sources to Grafana 

Such as the Prometheus of other clusters. In kube-prometheus-stack values, under `grafana` and flush with `ingress`, add (example):

```
additionalDataSources:
    - name: Dev-Prometheus
      type: prometheus
      url: https://prometheus.dev.cloud.statcan.ca
      access: proxy
    - name: ...and so on...
```

Other kinds of data sources [may have additional properties, such as credentials](https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources). 

The data source changes are not applied automatically, but require a restart of the Grafana part. Consider a rollout restart of the Grafana deployment. If an automatic workaround for this is needed, timestamp pod annotations are one option - [see the last comments here](https://github.com/coreos/prometheus-operator/issues/1909).

### To apply PrometheusRules

Apply PrometheusRule YAML manifests similar to the examples provided in this repo. When applying the rules to the Prometheus isntance installed by default through `kube-prometheus-stack`, ensure that the value of the `release` label matches the Helm release name corresponding to `kube-prometheus-stack`, [unless its `ruleSelector` has been overriden](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/templates/prometheus/prometheus.yaml#L202). Otherwise, match the `ruleSelector` of the desired Prometheus instance. Check and align with any `ruleNamespaceSelector` restrictions in place.

### To apply Alertmanager configuration

The Prometheus Operator Alertmanager expects its YAML configuarion in a secret as a base64 value of the key `alertmanager.yaml`. If notification templates are used, they should be separate data (also base64 encoded values) in the same secret, with keys that match the specification in the Alertmanager config. For example, if the Alertmanager config specifies:

```
templates:
- '*.tmpl'
- '*.html'
```

Then `slack.tmpl: <base64 encoded template>` and `email.html: <base64 encoded template>` are acceptable.

This can be done manually by creating a secret with multiple `--from-file` specifications or values in Helm charts that include Alertmanager.

### To configure a blackbox exporter
Refer to the [Blackbox Exporter Helm chart repo](https://github.com/helm/charts/tree/master/stable/prometheus-blackbox-exporter) and [sample Terraform helm_release configuration](blackbox-exporter-example.tf). Note the labels for the Prometheus Operator to pick up the service.
