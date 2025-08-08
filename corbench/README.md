# Automated Cortex E2E Testing and Benchmarking

## Corbench Setup

To deploy this tool, follow the steps here: [Getting Started](docs/deployment.md)

# Archetecture

![Cortex Benchmarking Archetecture](docs/Blank%20diagram%20(2).png)

1. START: User opens a Github PR in the cortex repository and sends a /corbench PR comment to start a benchmark test. Github then makes a POST request with the command as the payload to the Comment Monitor Webhook Server (step 2). 
2. The Comment Monitor Webhook Server monitors for /corbench calls from Cortex github PRs. Upon recieving a POST request from a Github PR, the server verifies the validity of the command (i.e. does the command exist?). The server then initiates a dispatch event to the PR (step 3) as well as posts an update comment indicating the status of the tests, links to grafana dashboards, etc, or a warning message if the command was used incorrectly/with wrong syntax.
3. The PR runs the dispatch event using the docker image of the Corbench repo code to initiate benchmarks (step 4). 
4. Within the Corbench docker image, two versions of Cortex that will be benchmarked are built & deployed in separate Kubernetes nodes to EKS. After this, we can start to deploy the metrics pushers (Avalanche). Avalanche instances will be deployed to EKS and will simulate prometheus instances pushing load to Cortex’s remote write (or other micro-service specific) endpoints with mock data.
6. While the Metrics Pushers push load into the Cortex instances, prometheus will continuously scrape metrics from the Cortex instances and the kubernetes nodes they run on.
7. Grafana displays collected benchmark metrics & github notifier notifies the original pr of results & other info
