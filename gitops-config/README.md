# GitOps Configuration Repository

This repository contains the GitOps configurations for the Phonebook application and infrastructure components using Argo CD.

## Repository Structure

```
gitops-config/
├── applications
│   ├── apps
│   │   └── phonebook
│   │       ├── application.yaml
│   │       └── values-prod.yaml
│   ├── infrastructure
│   │   ├── aws-ebs-csi
│   │   │   ├── application.yaml
│   │   │   └── storageclass.yaml
│   │   ├── cert-manager
│   │   │   └── application.yaml
│   │   ├── efk
│   │   │   ├── application-elasticsearch.yaml
│   │   │   ├── application-fluentbit.yaml
│   │   │   └── application-kibana.yaml
│   │   ├── monitoring
│   │   │   └── application.yaml
│   │   └── nginx-ingress
│   │       └── application.yaml
│   └── root-application.yaml
├── charts
│   ├── Chart.lock
│   ├── charts
│   │   └── mongodb-13.18.5.tgz
│   ├── Chart.yaml
│   ├── templates
│   │   ├── cluster-issuer.yaml
│   │   ├── deployment.yaml
│   │   ├── helpers.tpl
│   │   ├── ingress.yaml
│   │   ├── servicemonitor.yaml
│   │   └── service.yaml
│   └── values.yaml
└── README.md

```

## Quick Start

1. Access Argo CD UI:
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Get initial admin password:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

2. Access Prometheus UI for metrics and targets:
   ```bash
   kubectl port-forward svc/prometheus-prometheus -n monitoring 9090:9090
   ```

3. Access Grafana for dashboards:
   ```bash
   kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 9091:80
   ```
   Default credentials:
   - Username: admin
   - Password: prom-operator

4. Access Kibana for logs:
   ```bash
   kubectl port-forward -n logging svc/kibana-kibana 5601:5601
   ```
   Import dashboards via Management > Stack Management > Saved Objects

5. Update NoIP DNS:
   ```bash
   # Get LoadBalancer IP
   dig +short portfolioleon.ddns.net
   # Update NoIP with new IP if changed
   ```

## Applications

### Core Application
- **Phonebook**: Main application deployment with MongoDB
  - Location: `applications/apps/phonebook/`
  - Configuration: `values-prod.yaml`

### Infrastructure Components

1. **Cert Manager**
   - SSL/TLS certificate management
   - Automatic certificate renewal
   - Location: `applications/infrastructure/cert-manager/`

2. **Ingress Nginx**
   - Ingress controller for external access
   - SSL termination
   - Location: `applications/infrastructure/ingress-nginx/`

3. **Monitoring Stack**
   - Prometheus for metrics collection
   - Grafana for visualization
   - Location: `applications/infrastructure/monitoring/`

4. **Logging Stack**
   - Elasticsearch for log storage
   - Fluent Bit for log collection
   - Kibana for log visualization
   - Location: `applications/infrastructure/logging/`

## Sync Waves

Applications are deployed in the following order:
1. Storage and Certificate Management (Wave 0)
2. Ingress Controller and Monitoring (Wave 1)
3. Applications (Wave 2)

## Maintenance

### Adding New Applications
1. Create application directory under `applications/`
2. Add necessary Helm charts or manifests
3. Create an Application CR referencing the new resources
4. Update root application if needed

### Updating Configurations
1. Modify relevant values files
2. Commit and push changes
3. Argo CD will automatically sync changes

### Troubleshooting
1. Check Argo CD UI for sync status and errors
2. Verify application logs in Kibana
3. Check metrics in Prometheus/Grafana
4. Review ingress configurations for routing issues
