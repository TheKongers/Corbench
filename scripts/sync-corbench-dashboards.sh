#!/usr/bin/env bash

echo 'apiVersion: v1' > ../corbench/c-manifests/cluster-infra/grafana_dashboard_dashboards_noparse.yaml
echo 'kind: ConfigMap' >> ../corbench/c-manifests/cluster-infra/grafana_dashboard_dashboards_noparse.yaml
echo 'metadata:' >> ../corbench/c-manifests/cluster-infra/grafana_dashboard_dashboards_noparse.yaml
echo '  name: grafana-dashboards' >> ../corbench/c-manifests/cluster-infra/grafana_dashboard_dashboards_noparse.yaml
echo 'data:' >> ../corbench/c-manifests/cluster-infra/grafana_dashboard_dashboards_noparse.yaml

# Loop over files in ../corbench/c-manifests/cluster-infra/dashboards.
for file in $(ls ../corbench/c-manifests/cluster-infra/dashboards); do
    # Read the file content.
    content=$(cat ../corbench/c-manifests/cluster-infra/dashboards/$file)
    echo "  $file: |" >> ../corbench/c-manifests/cluster-infra/grafana_dashboard_dashboards_noparse.yaml
    echo "$content" | sed 's/^/    /' >> ../corbench/c-manifests/cluster-infra/grafana_dashboard_dashboards_noparse.yaml
done