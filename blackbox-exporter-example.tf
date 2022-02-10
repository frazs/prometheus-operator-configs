# You may need to use a proxy URL for the repository, which may require repository_username and repository_password. 
# You may need to use a proxy URL for the Helm value image.Repository, which may require adding image.pullSecrets.
# Helm value serviceMonitor.Defaults.Labels.Release must match the Helm release name corresponding to kube-prometheus-stack, unless you have configured an alternative form of ServiceMonitor discovery.

resource "helm_release" "blackbox-exporter" {
  name                = "blackbox-exporter"
  namespace           = monitoring
  # repository_username = var.docker_username
  # repository_password = var.docker_password
  repository          = "https://prometheus-community.github.io/helm-charts/"
  chart               = "prometheus-blackbox-exporter"
  version             = "5.3.1"

  values = [<<EOF
image:
  repository: prom/blackbox-exporter
  tag: v0.19.0
  pullPolicy: IfNotPresent

service:
  labels: 
    app: prometheus-blackbox-exporter
    jobLabel: blackbox-exporter

pod:
  labels: 
    app: prometheus-blackbox-exporter

serviceMonitor:
  enabled: true
  defaults:
    labels: 
      app: prometheus-blackbox-exporter
      release: kube-prometheus-stack
  targets:
    - name: example                   
      url: https://example.com
      interval: 60s
      scrapeTimeout: 60s
      module: http_2xx

EOF
  ]
}
