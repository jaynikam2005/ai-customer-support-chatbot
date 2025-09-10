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

# Expose port
EXPOSE 8080

# Set JVM options for Java 21
ENV JAVA_OPTS="-XX:+UseZGC -XX:+UnlockExperimentalVMOptions"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Start the application
ENTRYPOINT ["java", "-jar", "app.jar"]