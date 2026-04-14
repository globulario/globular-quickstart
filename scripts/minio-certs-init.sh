#!/bin/bash
set -euo pipefail

# minio-certs-init.sh — generates MinIO TLS certs from the shared cluster CA.
# Runs as an init container before MinIO starts.
# Writes certs to /minio-certs/ which is volume-mounted into MinIO at /root/.minio/certs/

CERT_DIR=/minio-certs
CA_DIR=/shared-pki

echo "[minio-tls] Waiting for cluster CA..."
for i in $(seq 1 120); do
    [ -f "$CA_DIR/ca.crt" ] && [ -f "$CA_DIR/ca.key" ] && break
    sleep 1
done
[ ! -f "$CA_DIR/ca.crt" ] && echo "FATAL: CA not available" && exit 1

echo "[minio-tls] Generating MinIO TLS certificate..."
mkdir -p "$CERT_DIR/CAs"

# Copy CA cert so MinIO trusts the cluster CA
cp "$CA_DIR/ca.crt" "$CERT_DIR/CAs/ca.crt"

# Generate MinIO server cert signed by the cluster CA
# SAN includes the MinIO IP, hostname, and the DNS name services use
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 \
    -out "$CERT_DIR/private.key" 2>/dev/null

openssl req -new -key "$CERT_DIR/private.key" \
    -out /tmp/minio.csr \
    -subj "/CN=minio.globular.internal" \
    -addext "subjectAltName=DNS:minio.globular.internal,DNS:scylladb,IP:10.10.0.12,IP:10.10.0.20" 2>/dev/null

openssl x509 -req -in /tmp/minio.csr \
    -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
    -out "$CERT_DIR/public.crt" -days 365 \
    -copy_extensions copyall 2>/dev/null

rm -f /tmp/minio.csr
echo "[minio-tls] MinIO certs generated."
ls -la "$CERT_DIR/"
