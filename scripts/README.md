## Grafana Dashboard Sync Script

This script updates the grafana dashboard deployment based on the grafana dashboard jsons in /corbench/c-manifests/cluster-infra/dashboards

Simply update the grafana dashboard json, then in this /scripts directory run the following script to update the config file

From Root Directory:
```bash
cd scripts/
./sync-corbench-dashboards.sh
```