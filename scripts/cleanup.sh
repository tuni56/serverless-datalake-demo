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

echo -e "${YELLOW}⚠ ADVERTENCIA: Esto eliminará TODOS los recursos de AWS${NC}"
echo -e "${YELLOW}⚠ Región: $REGION${NC}"
echo ""
echo "¿Estás seguro? (yes/no)"
read -r response

if [ "$response" != "yes" ]; then
    echo "Cleanup cancelado"
    exit 0
fi

cd terraform/environments/dev

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT="ecommerce-datalake"

echo ""
echo "================================================"
echo "  Paso 1: Vaciar buckets S3"
echo "================================================"

empty_bucket() {
    local BUCKET="$1"
    echo "Vaciando s3://$BUCKET ..."

    aws s3 rm s3://$BUCKET --recursive --region $REGION 2>/dev/null || true

    # Eliminar versiones y delete markers (paginado, JSON válido via jq)
    for TYPE in Versions DeleteMarkers; do
        while true; do
            PAYLOAD=$(aws s3api list-object-versions --bucket $BUCKET --region $REGION --output json 2>/dev/null \
                | jq -c "{Objects: (.${TYPE} // [] | map({Key:.Key, VersionId:.VersionId}))}")
            COUNT=$(echo $PAYLOAD | jq '.Objects | length')
            [ "$COUNT" -eq 0 ] && break
            aws s3api delete-objects --bucket $BUCKET --region $REGION --delete "$PAYLOAD" > /dev/null
        done
    done
}

for SUFFIX in raw curated scripts athena-results; do
    empty_bucket "${PROJECT}-${SUFFIX}-${ACCOUNT_ID}"
done

echo ""
echo "================================================"
echo "  Paso 2: Destruir infraestructura Terraform"
echo "================================================"

terraform destroy -auto-approve

echo ""
echo -e "${GREEN}✅ Cleanup completado. Todos los recursos de AWS fueron eliminados.${NC}"
