# Monitoring Stack Helpers

This folder contains resources for the CI/CD monitoring stack (SonarQube → Prometheus → Grafana).

## SonarQube Exporter

The official `return200/sonarqube-exporter` image has fragile parsing that crashes when SonarQube omits some fields.  
`infra/sonar-exporter` wraps that image with hardened helpers so the exporter keeps serving metrics even if certain
metrics are missing.

### Build & Run with Docker Compose

1. Copy your SonarQube monitoring token to an `.env` file at the repository root (the
   `infra/docker-compose.monitoring.yml` command looks for it there). Never add this file to Git.

   ```env
   SONARQUBE_TOKEN=squ_******************************
   SONARQUBE_SERVER=http://sonarqube:9000
   ```

2. Ensure a Docker network called `cicd-net` already exists (both Jenkins and SonarQube are attached to it):

   ```powershell
   docker network create cicd-net
   ```

3. Build and start the exporter:

   ```powershell
   docker compose -f infra/docker-compose.monitoring.yml up -d --build
   ```

4. Prometheus can now scrape `http://sonar-exporter:8198/metrics` (or `http://localhost:8198/metrics` from the host).

### Rebuild After Code Changes

```powershell
docker compose -f infra/docker-compose.monitoring.yml build sonar-exporter
docker compose -f infra/docker-compose.monitoring.yml up -d sonar-exporter
```

### Host & Container Metrics

- `node-exporter` (host port `9100`) exposes host metrics; `cadvisor` (host port `8085`, container port `8080`) provides per-container stats. Both are included in the compose file and attached to `cicd-net`.
- Prometheus job snippets:

  ```yaml
  scrape_configs:
    - job_name: node-exporter
      static_configs:
        - targets:
            - node-exporter:9100
    - job_name: cadvisor
      static_configs:
        - targets:
            - cadvisor:8080
  ```

### Prometheus Job Snippet (add to your `prometheus.yml`)

```yaml
scrape_configs:
  - job_name: sonar-exporter
    static_configs:
      - targets:
          - sonar-exporter:8198
```

> **Note:** Grafana dashboards can now point to the new Prometheus job to visualise SonarQube quality gate trends,
> issue counts, and technical debt metrics without any flaky exporter restarts.

### Host Integrations

- The Prometheus container expects its configuration at `D:\infra\prometheus\prometheus.yml` (bind mounted inside the
  container). Add the snippet above to the `scrape_configs` section and restart Prometheus:

  ```powershell
  docker restart prometheus
  ```

- Grafana is available at `http://localhost:3000` (default credentials `admin` / `admin` unless changed). Create a new
  dashboard and point panels at the `sonarqube-exporter` Prometheus job for SonarQube quality metrics.

### Nexus Artifact Repository

- The compose stack starts a Nexus 3 instance on `http://localhost:8083` (forwarded to container port `8081`).
- Persistent data resides in the named Docker volume `nexus-data`.
- First-time setup steps:
  1. Grab the bootstrap admin password:
     ```powershell
     docker exec nexus cat /nexus-data/admin.password
     ```
  2. Log in with user `admin` and the retrieved password, set a new admin password, and create the required repositories (e.g. hosted Maven releases, hosted Docker images).
- Add credentials to Jenkins:
  - Store a Nexus automation account (e.g. ID `nexus-admin`) and Docker Hub username/token (`dockerhub-creds`).
  - Run `docker login` on the Jenkins agent so Docker builds can push images.

### Application Deployment Compose File

- `infra/docker-compose.app.yml` deploys the Spring Boot backend (`backend` service) alongside MySQL (`mysql` service) on the shared `cicd-net` network.
- The file expects the environment variable `APP_IMAGE` to contain the full image reference that Jenkins pushed (e.g. `dockerhubuser/covoiturage-final:123`).
- Example manual run from PowerShell:

  ```powershell
  $env:APP_IMAGE = "dockerhubuser/covoiturage-final:123"
  docker compose -f infra/docker-compose.app.yml up -d
  ```

- Default database credentials are defined via environment variables; override them by exporting `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, and `MYSQL_ROOT_PASSWORD` before launching the stack.

