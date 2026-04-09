# todo-api

A Spring Boot REST API for managing Todo items, backed by MongoDB. Includes Prometheus/Micrometer metrics instrumentation via Spring Actuator.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Java | 11 |
| Maven | 3.6+ (or use `./mvnw` wrapper — no install needed) |
| MongoDB | 4.x+ |
| Docker | 20.x+ (for containerised runs only) |

MongoDB must be running and accessible before starting the app. The default connection URI is:

```
mongodb://root:password@localhost:27017/todo?authSource=admin
```

---

## Project structure

```
todo-api/
├── src/
│   ├── main/
│   │   ├── java/com/pavan/todo/
│   │   │   ├── TodoApplication.java       # Entry point
│   │   │   ├── controllers/               # REST controllers
│   │   │   ├── models/                    # Todo document model
│   │   │   ├── repositories/              # Spring Data MongoDB repo
│   │   │   └── services/                  # Business logic + metrics
│   │   └── resources/
│   │       └── application.properties     # App configuration
│   └── test/
├── Dockerfile
└── pom.xml
```

---

## Maven commands

All commands below use the Maven wrapper (`./mvnw`). Replace with `mvn` if Maven is installed globally.

### Clean and compile

```bash
./mvnw clean compile
```

### Run tests

```bash
./mvnw test
```

### Package (build the JAR)

```bash
./mvnw clean package
```

The JAR is output to `target/todo-1.0.0.jar`.

### Package without running tests

```bash
./mvnw clean package -DskipTests
```

### Run the application directly with Maven

```bash
./mvnw spring-boot:run
```

### Run with a custom MongoDB URI

```bash
./mvnw spring-boot:run \
  -Dspring-boot.run.arguments="--spring.data.mongodb.uri=mongodb://root:password@localhost:27017/todo?authSource=admin"
```

### Run with a custom port

```bash
./mvnw spring-boot:run \
  -Dspring-boot.run.arguments="--server.port=8083"
```

### Run the packaged JAR directly

```bash
java -jar target/todo-1.0.0.jar
```

### Clean build artifacts

```bash
./mvnw clean
```

The app starts on **port 8082** by default (configured in `application.properties`).

---

## Docker Compose (recommended)

The easiest way to run the full stack locally — starts both the app and MongoDB together.

### 1. Build the JAR first

```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean package -DskipTests
```

### 2. Start all services

```bash
docker-compose up -d
```

### 3. Check service status

```bash
docker-compose ps
```

### 4. View logs

```bash
# All services
docker-compose logs -f

# App only
docker-compose logs -f todo-api

# MongoDB only
docker-compose logs -f mongo
```

### 5. Stop all services

```bash
docker-compose down
```

### 6. Stop and remove volumes (wipes MongoDB data)

```bash
docker-compose down -v
```

### 7. Rebuild after code changes

```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean package -DskipTests && docker-compose up -d --build
```

---

## Docker (manual)

### 1. Build the JAR first

Docker copies the JAR from `target/`. Build it before building the image:

```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean package -DskipTests
```

### 2. Build the Docker image

```bash
docker build -t todo-api:1.0.0 .
```

### 3. Run the container

```bash
docker run -d \
  --name todo-api \
  -p 8082:8082 \
  -e SPRING_DATA_MONGODB_URI="mongodb://root:password@host.docker.internal:27017/todo?authSource=admin" \
  todo-api:1.0.0
```

> **Note:** The Dockerfile contains `EXPOSE 8080`, but the application binds to port **8082**. Use `-p 8082:8082` to match the actual runtime port.
>
> `host.docker.internal` resolves to the Docker host on Mac/Windows. On Linux, use `--add-host=host.docker.internal:host-gateway` or replace with the host's IP.

### 4. View container logs

```bash
docker logs -f todo-api
```

### 5. Stop and remove the container

```bash
docker stop todo-api && docker rm todo-api
```

### Build with a different Java version

```bash
docker build --build-arg JAVA_VERSION="17-jdk-slim" -t todo-api:1.0.0 .
```

---

## API endpoints

Base URL: `http://localhost:8082`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/todos` | List all todos |
| `POST` | `/api/todos` | Create a todo |
| `PUT` | `/api/todos/{id}` | Update a todo |
| `PATCH` | `/api/todos/{id}/complete` | Mark a todo as completed |
| `DELETE` | `/api/todos/{id}` | Delete a todo |
| `GET` | `/api/test/slow?delay=N` | Slow endpoint for metrics testing (sleeps up to 9s) |

### Example: Create a todo

```bash
curl -X POST http://localhost:8082/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title": "Buy groceries"}'
```

### Example: List all todos

```bash
curl http://localhost:8082/api/todos
```

### Example: Mark as completed

```bash
curl -X PATCH http://localhost:8082/api/todos/<id>/complete
```

---

## Todo model

| Field | Type | Constraints |
|-------|------|-------------|
| `id` | String | Auto-generated (`@Id`) |
| `title` | String | Required, max 255 chars, unique |
| `completed` | boolean | Default: `false` |
| `createdAt` | Date | Default: current timestamp |

---

## Configuration

All configuration lives in `src/main/resources/application.properties`.

| Property | Default | Description |
|----------|---------|-------------|
| `spring.data.mongodb.uri` | `mongodb://root:password@localhost:27017/todo?authSource=admin` | MongoDB connection URI |
| `server.port` | `8082` | HTTP port |
| `management.endpoints.web.exposure.include` | `*` | Exposes all Actuator endpoints |

Override any property at runtime:

```bash
java -jar target/todo-1.0.0.jar --server.port=9090
```

---

## Metrics and monitoring

The app exposes Spring Actuator endpoints and Prometheus metrics.

| Endpoint | Description |
|----------|-------------|
| `GET /actuator/health` | Application health status |
| `GET /actuator/metrics` | Available metrics list |
| `GET /actuator/prometheus` | Prometheus scrape endpoint |

Custom metrics tracked:

| Metric | Type | Description |
|--------|------|-------------|
| `todo.created.count` | Counter | Increments on each todo created |
| `todo.pending.count` | Gauge | Count of incomplete todos (updated every 3 seconds) |

HTTP request histograms are configured with SLO buckets at **50ms, 100ms, 200ms, 400ms** and percentiles at p50, p90, p95, p99, p99.9.

---

## Kubernetes

All manifests live in [k8s/](k8s/). Numbered filenames guarantee correct apply order.

```
k8s/
├── 00-namespace.yaml        # Namespace: todo
├── 01-mongo-secret.yaml     # MongoDB credentials (base64 encoded)
├── 02-mongo-pvc.yaml        # 1Gi PersistentVolumeClaim for MongoDB data
├── 03-mongo-deployment.yaml # MongoDB Deployment (single replica, Recreate strategy)
├── 04-mongo-service.yaml    # MongoDB ClusterIP Service (internal only)
├── 05-todo-configmap.yaml   # Non-sensitive app config (port, actuator settings)
├── 06-todo-deployment.yaml  # todo-api Deployment with init container + health probes
└── 07-todo-service.yaml     # todo-api NodePort Service → localhost:30082
```

### Prerequisites

Build the Docker image before deploying (Docker Desktop shares the daemon with k8s):

```bash
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean package -DskipTests
docker build -t todo-api:1.0.0 .
```

### Deploy everything (one command)

```bash
kubectl apply -f k8s/
```

### Check status

```bash
# All resources in the namespace
kubectl get all -n todo

# Watch pods come up
kubectl get pods -n todo -w

# Describe a pod if it's not starting
kubectl describe pod -l app=todo-api -n todo
kubectl describe pod -l app=mongo -n todo
```

### View logs

```bash
# todo-api logs
kubectl logs -f deployment/todo-api -n todo

# MongoDB logs
kubectl logs -f deployment/mongo -n todo
```

### Access the app

With NodePort the app is available at:

```
http://localhost:30082/api/todos
http://localhost:30082/actuator/health
```

### Tear down

```bash
# Remove all resources but keep the namespace
kubectl delete -f k8s/ --ignore-not-found

# Remove everything including the namespace
kubectl delete namespace todo
```

### Useful kubectl commands

| Action | Command |
|--------|---------|
| List all pods | `kubectl get pods -n todo` |
| Shell into app pod | `kubectl exec -it deployment/todo-api -n todo -- sh` |
| Shell into MongoDB | `kubectl exec -it deployment/mongo -n todo -- mongosh -u root -p password` |
| Restart app | `kubectl rollout restart deployment/todo-api -n todo` |
| Scale app | `kubectl scale deployment/todo-api --replicas=2 -n todo` |
| Port-forward app | `kubectl port-forward svc/todo-api-service 8082:8082 -n todo` |
| Port-forward mongo | `kubectl port-forward svc/mongo-service 27017:27017 -n todo` |

---

## Tech stack

| Component | Technology |
|-----------|------------|
| Framework | Spring Boot 2.5.2 |
| Language | Java 11 |
| Build | Maven 3 (Maven wrapper included) |
| Database | MongoDB |
| Metrics | Micrometer + Prometheus |
| Validation | Spring Validation (JSR-303) |
| Utilities | Lombok |


One gotcha to be aware of
The Dockerfile has EXPOSE 8080, but the app actually binds to 8082 (set in application.properties). Always map -p 8082:8082 when running the container. When running with Docker, also pass the MongoDB URI via -e so localhost in the properties resolves to the host machine, not inside the container.


Maven commands
Goal	Command
Compile	./mvnw clean compile
Run tests	./mvnw test
Package JAR	./mvnw clean package
Package (skip tests)	./mvnw clean package -DskipTests
Run the app	./mvnw spring-boot:run
Run packaged JAR	java -jar target/todo-1.0.0.jar
Clean artifacts	./mvnw clean
The app starts on port 8082.

Docker commands

# 1. Build JAR first (Docker copies from target/)
./mvnw clean package -DskipTests

# 2. Build the image
docker build -t todo-api:1.0.0 .

# 3. Run (note: -p 8082:8082 — NOT 8080, despite what the Dockerfile EXPOSE says)
docker run -d --name todo-api -p 8082:8082 \
  -e SPRING_DATA_MONGODB_URI="mongodb://root:password@host.docker.internal:27017/todo?authSource=admin" \
  todo-api:1.0.0


One gotcha to be aware of
The Dockerfile has EXPOSE 8080, but the app actually binds to 8082 (set in application.properties). Always map -p 8082:8082 when running the container. When running with Docker, also pass the MongoDB URI via -e so localhost in the properties resolves to the host machine, not inside the container.

Updated quick-reference — replace ./mvnw with mvn for now:

Goal	Command
Compile	mvn clean compile
Run tests	mvn test
Package JAR	mvn clean package
Package (skip tests)	mvn clean package -DskipTests
Run the app	mvn spring-boot:run
Restore wrapper	mvn wrapper:wrapper


Now run Maven with Java 17 explicitly (since Maven defaults to Java 25 on your machine):


JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean compile
This is the recommended command going forward for all Maven operations on this project:

Goal	Command
Compile	JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean compile
Package	JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean package -DskipTests
Run	JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn spring-boot:run
Why this happened:

mvn on your machine uses OpenJDK 25 (installed by Homebrew as a Maven dependency)
Lombok 1.18.20 (bundled with Spring Boot 2.5.2) only supports up to Java 15
The upgraded Lombok 1.18.36 supports Java 17–23; paired with JAVA_HOME pointing to Java 17, annotation processing will work correctly
To avoid typing JAVA_HOME=... every time, you can export it in your terminal session:


export JAVA_HOME=$(/usr/libexec/java_home -v 17)


----
Docker is running. Spin up MongoDB with a single command — matching the exact credentials in application.properties:


docker run -d \
  --name mongo-todo \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=root \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  mongo:6
Then start the app again:


JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn spring-boot:run
Useful MongoDB container commands:

Action	Command
Stop MongoDB	docker stop mongo-todo
Start it again	docker start mongo-todo
Remove it	docker rm -f mongo-todo
Check logs	docker logs mongo-todo
Open Mongo shell	docker exec -it mongo-todo mongosh -u root -p password
The credentials (root / password) and port (27017) match exactly what's in application.properties, so no config changes needed.

-----
Services:

Service	Image	Port	Notes
mongo	mongo:6	27017	Persisted via named volume, health-checked
todo-api	Built from Dockerfile	8082	Waits for mongo to be healthy before starting
Key details:

todo-api overrides SPRING_DATA_MONGODB_URI so it connects to the mongo container (not localhost)
MongoDB data is persisted in mongo-data volume — survives container restarts
todo-api only starts after MongoDB passes its health check (depends_on: condition: service_healthy)
Both services share a private todo-network bridge network

To run the full stack:

# Step 1 — build the JAR
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean package -DskipTests

# Step 2 — start everything
docker compose up -d

# Step 3 — check it's running
docker-compose ps
App will be available at http://localhost:8082/api/todos

# Step 4 — to stop and remove all
docker compose down -v

-----


Files created in k8s/:

File	What it does
00-namespace.yaml	Creates todo namespace
01-mongo-secret.yaml	MongoDB credentials (base64)
02-mongo-pvc.yaml	1Gi persistent volume for MongoDB data
03-mongo-deployment.yaml	MongoDB pod with liveness/readiness probes
04-mongo-service.yaml	ClusterIP — MongoDB accessible only inside cluster
05-todo-configmap.yaml	Non-sensitive app config
06-todo-deployment.yaml	App pod — init container waits for Mongo, health probes via /actuator/health
07-todo-service.yaml	NodePort — app accessible at localhost:30082
To deploy:


# 1. Build image
JAVA_HOME=$(/usr/libexec/java_home -v 17) mvn clean package -DskipTests
docker build -t todo-api:1.0.0 .

# 2. Deploy everything
kubectl apply -f k8s/

# 3. Watch pods start
kubectl get pods -n todo -w
App will be live at http://localhost:30082/api/todos once both pods are Running.

