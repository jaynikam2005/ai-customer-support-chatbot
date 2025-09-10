# backend-java/Dockerfile
FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Install Maven
RUN apk add --no-cache maven

# Copy maven files
COPY pom.xml .
COPY src src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Install curl for healthcheck
RUN apk add --no-cache curl

# Copy the built JAR
COPY --from=build /app/target/*.jar app.jar

# Create config directory for additional properties files
RUN mkdir -p /app/config

# Expose port
EXPOSE 8080

# Set JVM options for Java 21
ENV JAVA_OPTS="-XX:+UseZGC -XX:+UnlockExperimentalVMOptions"
ENV SERVER_PORT=8080
ENV SPRING_CONFIG_ADDITIONAL_LOCATION=file:/app/config/

# Health check with dynamic port
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD curl -f http://localhost:${SERVER_PORT:-8080}/actuator/health || exit 1

# Create a startup script that can accept additional JVM arguments
RUN echo '#!/bin/sh\n\
JVM_ARGS="$JAVA_OPTS"\n\
exec java $JVM_ARGS -jar app.jar' > /app/start.sh && \
    chmod +x /app/start.sh

# Start the application
ENTRYPOINT ["/app/start.sh"]