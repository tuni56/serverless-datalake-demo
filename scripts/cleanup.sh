#!/bin/bash

set -e

echo "================================================"
echo "  Cleanup - Serverless Data Lake Demo"
echo "================================================"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

REGION=${1:-us-east-2}

echo -e "${YELLOW}⚠ ADVERTENCIA: Esto eliminará todos los recursos de AWS${NC}"
echo -e "${YELLOW}⚠ Región: $REGION${NC}"
echo ""
echo "¿Estás seguro? (yes/no)"
read -r response

if [ "$response" != "yes" ]; then
    echo "Cleanup cancelado"
    exit 0
fi

cd terraform/environments/dev

# Obtener nombres de buckets antes de destruir
RAW_BUCKET=$(terraform output -raw raw_bucket_name 2>/dev/null || echo "")
CURATED_BUCKET=$(terraform output -raw curated_bucket_name 2>/dev/null || echo "")
SCRIPTS_BUCKET=$(terraform output -raw scripts_bucket_name 2>/dev/null || echo "")
ATHENA_BUCKET=$(terraform output -raw athena_results_bucket_name 2>/dev/null || echo "")

echo ""
echo "================================================"
echo "  Paso 1: Vaciar buckets S3"
echo "================================================"

if [ -n "$RAW_BUCKET" ]; then
    echo "Vaciando $RAW_BUCKET..."
    aws s3 rm s3://$RAW_BUCKET --recursive --region $REGION 2>/dev/null || true
fi

if [ -n "$CURATED_BUCKET" ]; then
    echo "Vaciando $CURATED_BUCKET..."
    aws s3 rm s3://$CURATED_BUCKET --recursive --region $REGION 2>/dev/null || true
fi

if [ -n "$SCRIPTS_BUCKET" ]; then
    echo "Vaciando $SCRIPTS_BUCKET..."
    aws s3 rm s3://$SCRIPTS_BUCKET --recursive --region $REGION 2>/dev/null || true
fi

if [ -n "$ATHENA_BUCKET" ]; then
    echo "Vaciando $ATHENA_BUCKET..."
    aws s3 rm s3://$ATHENA_BUCKET --recursive --region $REGION 2>/dev/null || true
fi

echo ""
echo "================================================"
echo "  Paso 2: Destruir infraestructura Terraform"
echo "================================================"

terraform destroy -auto-approve

echo ""
echo "================================================"
echo "  Paso 3: Limpiar archivos locales"
echo "================================================"

cd ../../..

if [ -d "data-generator/output" ]; then
    echo "Eliminando datos generados..."
    rm -rf data-generator/output
fi

if [ -d "data-generator/.venv" ]; then
    echo "Eliminando entorno virtual..."
    rm -rf data-generator/.venv
fi

echo ""
echo -e "${GREEN}✅ Cleanup completado${NC}"
echo ""
echo "Recursos eliminados:"
echo "  - Buckets S3 y contenido"
echo "  - Glue Database, Crawlers y Jobs"
echo "  - Athena Workgroup"
echo "  - IAM Roles y Policies"
echo "  - Datos locales generados"
