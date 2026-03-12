#!/bin/bash

set -e

echo "================================================"
echo "  Setup - Serverless Data Lake Demo"
echo "================================================"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI no está instalado"
    exit 1
fi

echo -e "${GREEN}✓${NC} AWS CLI instalado"

# Verificar Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform no está instalado"
    exit 1
fi

echo -e "${GREEN}✓${NC} Terraform instalado"

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 no está instalado"
    exit 1
fi

echo -e "${GREEN}✓${NC} Python 3 instalado"

# Obtener Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓${NC} AWS Account ID: $ACCOUNT_ID"

# Obtener región
REGION=$(aws configure get region)
if [ -z "$REGION" ]; then
    REGION="us-east-2"
fi
echo -e "${GREEN}✓${NC} AWS Region: $REGION"

echo ""
echo "================================================"
echo "  Paso 1: Generar datos sintéticos"
echo "================================================"

cd data-generator

if [ ! -d ".venv" ]; then
    echo "Creando entorno virtual con uv..."
    uv venv
fi

source .venv/bin/activate
uv pip install -q -r requirements.txt

echo "Generando datos..."
python generate_ecommerce_data.py

cd ..

echo ""
echo "================================================"
echo "  Paso 2: Desplegar infraestructura"
echo "================================================"

cd terraform/environments/dev

# Copiar tfvars si no existe
if [ ! -f "terraform.tfvars" ]; then
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${YELLOW}⚠${NC} Revisa terraform.tfvars antes de continuar"
fi

echo "Inicializando Terraform..."
terraform init

echo "Validando configuración..."
terraform validate

echo "Planeando despliegue..."
terraform plan -out=tfplan

echo ""
echo -e "${YELLOW}¿Deseas aplicar los cambios? (yes/no)${NC}"
read -r response

if [ "$response" = "yes" ]; then
    terraform apply tfplan
    
    # Obtener outputs
    RAW_BUCKET=$(terraform output -raw raw_bucket_name)
    SCRIPTS_BUCKET=$(terraform output -raw scripts_bucket_name)
    
    echo ""
    echo "================================================"
    echo "  Paso 3: Subir datos y scripts a S3"
    echo "================================================"
    
    cd ../../..
    
    echo "Subiendo datos raw..."
    aws s3 cp data-generator/output/customers.csv s3://$RAW_BUCKET/customers/ --region $REGION
    aws s3 cp data-generator/output/products.csv s3://$RAW_BUCKET/products/ --region $REGION
    aws s3 cp data-generator/output/orders.csv s3://$RAW_BUCKET/orders/ --region $REGION
    
    echo "Subiendo script de Glue..."
    aws s3 cp glue-jobs/transform_raw_to_curated.py s3://$SCRIPTS_BUCKET/ --region $REGION
    
    echo ""
    echo -e "${GREEN}✅ Setup completado exitosamente${NC}"
    echo ""
    echo "Próximos pasos:"
    echo "1. Ejecutar Glue Crawler:"
    echo "   aws glue start-crawler --name ecommerce-datalake-raw-crawler-dev --region $REGION"
    echo ""
    echo "2. Ejecutar Glue ETL Job:"
    echo "   aws glue start-job-run --job-name ecommerce-datalake-transform-dev --region $REGION"
    echo ""
    echo "3. Consultar con Athena usando las queries en queries/sample_queries.sql"
else
    echo "Despliegue cancelado"
fi
