# Guía de Deployment

## Prerrequisitos

1. **AWS CLI** configurado con credenciales
2. **Terraform** >= 1.5
3. **Python** 3.9+
4. **uv** (Python package manager)
5. **Git** para control de versiones

### Instalar uv

```bash
# Linux/macOS
curl -LsSf https://astral.sh/uv/install.sh | sh

# O con pip
pip install uv
```

## Paso a Paso

### 1. Clonar el Repositorio

```bash
git clone <repository-url>
cd serverless-datalake-demo
```

### 2. Configurar Credenciales AWS

```bash
aws configure
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-2
# Default output format: json
```

Verificar configuración:
```bash
aws sts get-caller-identity
```

### 3. Generar Datos Sintéticos

```bash
cd data-generator
uv venv
source .venv/bin/activate  # En Windows: .venv\Scripts\activate
uv pip install -r requirements.txt
python generate_ecommerce_data.py
```

Esto generará ~50MB de datos CSV en `data-generator/output/`:
- `customers.csv` (10,000 registros)
- `products.csv` (500 registros)
- `orders.csv` (50,000 registros)

### 4. Configurar Variables de Terraform

```bash
cd ../terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Editar `terraform.tfvars` si es necesario (valores por defecto son adecuados para la demo).

### 5. Desplegar Infraestructura

```bash
# Inicializar Terraform
terraform init

# Validar configuración
terraform validate

# Ver plan de ejecución
terraform plan

# Aplicar cambios
terraform apply
```

Confirmar con `yes` cuando se solicite.

**Tiempo estimado**: 2-3 minutos

**Recursos creados**:
- 4 buckets S3 (raw, curated, scripts, athena-results)
- 2 IAM roles (Glue Crawler, Glue Job)
- 1 Glue Database
- 2 Glue Crawlers (raw, curated)
- 1 Glue ETL Job
- 1 Athena Workgroup

### 6. Subir Datos a S3

Obtener nombre del bucket raw:
```bash
RAW_BUCKET=$(terraform output -raw raw_bucket_name)
echo $RAW_BUCKET
```

Subir archivos CSV:
```bash
cd ../../..
aws s3 cp data-generator/output/customers.csv s3://$RAW_BUCKET/customers/ --region us-east-2
aws s3 cp data-generator/output/products.csv s3://$RAW_BUCKET/products/ --region us-east-2
aws s3 cp data-generator/output/orders.csv s3://$RAW_BUCKET/orders/ --region us-east-2
```

Verificar:
```bash
aws s3 ls s3://$RAW_BUCKET/ --recursive --region us-east-2
```

### 7. Subir Script de Glue

```bash
SCRIPTS_BUCKET=$(terraform output -raw scripts_bucket_name)
aws s3 cp glue-jobs/transform_raw_to_curated.py s3://$SCRIPTS_BUCKET/ --region us-east-2
```

### 8. Ejecutar Glue Crawler (Raw)

```bash
aws glue start-crawler --name ecommerce-datalake-raw-crawler-dev --region us-east-2
```

Monitorear estado:
```bash
aws glue get-crawler --name ecommerce-datalake-raw-crawler-dev --region us-east-2 --query 'Crawler.State'
```

Esperar hasta que el estado sea `READY` (2-3 minutos).

Verificar tablas creadas:
```bash
aws glue get-tables --database-name ecommerce-datalake-dev --region us-east-2
```

### 9. Ejecutar Glue ETL Job

```bash
aws glue start-job-run --job-name ecommerce-datalake-transform-dev --region us-east-2
```

Obtener Job Run ID:
```bash
JOB_RUN_ID=$(aws glue get-job-runs --job-name ecommerce-datalake-transform-dev --region us-east-2 --query 'JobRuns[0].Id' --output text)
```

Monitorear estado:
```bash
aws glue get-job-run --job-name ecommerce-datalake-transform-dev --run-id $JOB_RUN_ID --region us-east-2 --query 'JobRun.JobRunState'
```

**Tiempo estimado**: 5-10 minutos

### 10. Ejecutar Glue Crawler (Curated)

```bash
aws glue start-crawler --name ecommerce-datalake-curated-crawler-dev --region us-east-2
```

Esperar hasta que termine (2-3 minutos).

### 11. Consultar con Athena

#### Opción A: AWS Console

1. Ir a [Athena Console](https://console.aws.amazon.com/athena/)
2. Seleccionar Workgroup: `ecommerce-datalake-workgroup-dev`
3. Seleccionar Database: `ecommerce-datalake-dev`
4. Ejecutar queries desde `queries/sample_queries.sql`

#### Opción B: AWS CLI

```bash
# Query de ejemplo: Ventas totales por mes
aws athena start-query-execution \
  --query-string "SELECT year, month, COUNT(*) as total_orders, SUM(total_amount) as revenue FROM orders WHERE status = 'completed' GROUP BY year, month ORDER BY year DESC, month DESC LIMIT 12;" \
  --query-execution-context Database=ecommerce-datalake-dev \
  --result-configuration OutputLocation=s3://$(terraform output -raw athena_results_bucket_name)/ \
  --work-group ecommerce-datalake-workgroup-dev \
  --region us-east-2
```

## Troubleshooting

### Error: "Access Denied" al subir a S3

Verificar permisos IAM del usuario AWS CLI.

### Glue Crawler no encuentra datos

Verificar que los archivos CSV estén en las rutas correctas:
- `s3://BUCKET/customers/customers.csv`
- `s3://BUCKET/products/products.csv`
- `s3://BUCKET/orders/orders.csv`

### Glue Job falla

Ver logs en CloudWatch:
```bash
aws logs tail /aws-glue/jobs/output --follow --region us-east-2
```

### Athena query falla

Verificar que:
1. El Crawler haya terminado exitosamente
2. Las tablas existan en el Data Catalog
3. El Workgroup esté configurado correctamente

## Cleanup

Para eliminar todos los recursos y evitar costos:

```bash
./scripts/cleanup.sh
```

O manualmente:

```bash
# 1. Vaciar buckets
aws s3 rm s3://BUCKET-NAME --recursive --region us-east-2

# 2. Destruir infraestructura
cd terraform/environments/dev
terraform destroy
```

## Costos Estimados

Ver [cost-analysis.md](cost-analysis.md) para detalles completos.

**Resumen**: < $5 USD para la demo completa con capa gratuita.

## Próximos Pasos

1. Explorar queries adicionales en `queries/sample_queries.sql`
2. Modificar el Glue Job para agregar transformaciones
3. Implementar particionamiento adicional
4. Configurar Glue Triggers para automatización
5. Integrar con QuickSight para visualizaciones
