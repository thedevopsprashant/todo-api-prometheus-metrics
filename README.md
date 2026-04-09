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

## Docker

### 1. Build the JAR first

Docker copies the JAR from `target/`. Build it before building the image:

```bash
./mvnw clean package -DskipTests
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

