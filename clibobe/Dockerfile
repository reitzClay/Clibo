# --- Stage 1: Build the Application ---
FROM maven:3-eclipse-temurin-21-alpine AS builder
LABEL authors="Clayton Reitz"
LABEL project="clibobe"
WORKDIR /app

# Copy the build configuration files
COPY pom.xml .

# Fetch dependencies first (highly cached layer)
RUN mvn dependency:go-offline -B

# Copy the actual application source code
COPY src ./src

# Build the project and package the .jar file (skipping unit tests for speed)
RUN mvn package -DskipTests

# --- Stage 2: Runtime Environment ---
FROM eclipse-temurin:21-alpine
WORKDIR /app

# Copy the compiled JAR file from the builder stage
COPY --from=builder /app/target/clibobe-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080 to the outside world
EXPOSE 8080

# Execute the application
ENTRYPOINT ["java", "-jar", "app.jar"]
