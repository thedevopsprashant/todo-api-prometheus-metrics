# Download Java
ARG JAVA_VERSION="11-jdk-slim"
FROM openjdk:${JAVA_VERSION}

LABEL version="1.0.0"

ENV PROJECT_NAME="todo-api"

ARG APP_HOME="/opt/deployment/"

# Copy the jar from local to image
RUN mkdir -p ${APP_HOME}
COPY target/todo-1.0.0.jar ${APP_HOME}/todo-1.0.0.jar

WORKDIR ${APP_HOME}

EXPOSE 8080

# Run application with java -jar
ENTRYPOINT ["java", "-jar", "todo-1.0.0.jar"]