# Use a Go base image for building the application
FROM golang:latest as builder

# Set working directory inside the container
WORKDIR /app

# Install necessary packages
RUN apt-get update && apt-get install -y ca-certificates openssl

ARG cert_location=/usr/local/share/ca-certificates

# Get certificates
RUN openssl s_client -showcerts -connect github.com:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > ${cert_location}/github.crt
RUN openssl s_client -showcerts -connect proxy.golang.org:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > ${cert_location}/proxy.golang.crt
RUN update-ca-certificates

# Copy the Go module files and download dependencies
COPY broker-service/go.mod broker-service/go.sum ./
RUN go mod download

# Copy the rest of the application files
COPY broker-service/ ./

# Build the application binary
RUN CGO_ENABLED=0 go build -o brokerApp ./cmd/api

# Start a minimal image to run the application
FROM alpine:latest

# Create app directory and install required packages
RUN mkdir /app
RUN apk --update add --no-cache ca-certificates openssl git tzdata && \
    update-ca-certificates

# Copy the built binary from the builder stage
COPY --from=builder /app/brokerApp /app/brokerApp

# Set the command to run the binary
CMD [ "/app/brokerApp" ]
