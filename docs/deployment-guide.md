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

Editar `terraform.tfvars` y configurar el email para alertas:
```hcl
alert_email = "tu-email@example.com"
```

> ⚠️ Después del `terraform apply`, AWS enviará un email de confirmación a esa dirección. Debes confirmar la suscripción para recibir alertas de CloudWatch.

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
- 1 VPC con 2 subnets privadas, route table, security group
- 2 VPC Endpoints (S3 Gateway + Glue Interface)
- 4 buckets S3 (raw, curated, scripts, athena-results)
- 3 IAM roles (Glue Crawler, Glue Job con permisos EC2/VPC, Lambda)
- 2 colas SQS (glue-trigger + DLQ)
- 1 función Lambda (SQS → Glue trigger)
- 1 Glue Database
- 2 Glue Crawlers (raw, curated)
- 1 Glue ETL Job con VPC Connection (tipo NETWORK)
- 1 Athena Workgroup (engine v3 / Trino)
- CloudWatch Alarms + SNS Topic + Dashboard

### 6. Subir Script de Glue y Datos a S3

Obtener nombres de los buckets:
```bash
RAW_BUCKET=$(terraform output -raw raw_bucket_name)
SCRIPTS_BUCKET=$(terraform output -raw scripts_bucket_name 2>/dev/null || echo "ecommerce-datalake-scripts-$(aws sts get-caller-identity --query Account --output text)")
```

Subir script de Glue (debe hacerse antes de ejecutar el job):
```bash
aws s3 cp ../../../glue-jobs/transform_raw_to_curated.py s3://$SCRIPTS_BUCKET/ --region us-east-2
```

Subir archivos CSV:
```bash
aws s3 cp ../../../data-generator/output/customers.csv s3://$RAW_BUCKET/customers/ --region us-east-2
aws s3 cp ../../../data-generator/output/products.csv s3://$RAW_BUCKET/products/ --region us-east-2
aws s3 cp ../../../data-generator/output/orders.csv s3://$RAW_BUCKET/orders/ --region us-east-2
```

> 💡 Al subir archivos a `orders/`, S3 envía un evento a la cola SQS, que dispara automáticamente la Lambda, que a su vez inicia el Glue ETL Job.

Verificar:
```bash
aws s3 ls s3://$RAW_BUCKET/ --recursive --region us-east-2
```

Verificar que el mensaje llegó a SQS (debería procesarse rápido):
```bash
aws sqs get-queue-attributes \
  --queue-url $(terraform output -raw sqs_queue_url 2>/dev/null || echo "ver consola SQS") \
  --attribute-names ApproximateNumberOfMessages \
  --region us-east-2
```

### 7. Verificar Pipeline Automático

El pipeline se dispara automáticamente al subir `orders.csv`. Verificar el estado del Glue Job:

```bash
aws glue get-job-runs --job-name ecommerce-datalake-transform-dev --region us-east-2 \
  --query 'JobRuns[0].{State:JobRunState,Error:ErrorMessage,Duration:ExecutionTime}' --output table
```

Verificar datos curated generados:
```bash
aws s3 ls s3://$(terraform output -raw curated_bucket_name)/ --recursive --region us-east-2
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

El job se dispara automáticamente vía Lambda cuando se suben archivos a `orders/` en el bucket raw. Para ejecutarlo manualmente:

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

> **Nota**: La tabla `orders` usa Partition Projection, por lo que no necesita `MSCK REPAIR TABLE` ni crawler para descubrir particiones. Las tablas `customers` y `products` se crean manualmente vía DDL ya que son archivos Parquet sin particiones.

#### Crear tablas customers y products (una sola vez)

```sql
CREATE EXTERNAL TABLE `ecommerce-datalake_dev`.`customers` (
  `customer_id` bigint, `name` string, `email` string,
  `country` string, `registration_date` timestamp
) STORED AS PARQUET
LOCATION 's3://CURATED_BUCKET/customers/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');

CREATE EXTERNAL TABLE `ecommerce-datalake_dev`.`products` (
  `product_id` bigint, `name` string, `category` string,
  `price` double, `stock` int
) STORED AS PARQUET
LOCATION 's3://CURATED_BUCKET/products/'
TBLPROPERTIES ('parquet.compression'='SNAPPY');
```

#### Crear tabla orders con Partition Projection

```sql
CREATE EXTERNAL TABLE `ecommerce-datalake_dev`.`orders` (
  `order_id` bigint, `customer_id` bigint, `product_id` bigint,
  `order_date` timestamp, `quantity` int, `total_amount` double, `status` string
) PARTITIONED BY (`year` int, `month` int)
STORED AS PARQUET
LOCATION 's3://CURATED_BUCKET/orders/'
TBLPROPERTIES (
  'parquet.compression'='SNAPPY',
  'projection.enabled'='true',
  'projection.year.type'='integer',
  'projection.year.range'='2025,2026',
  'projection.month.type'='integer',
  'projection.month.range'='1,12',
  'storage.location.template'='s3://CURATED_BUCKET/orders/year=${year}/month=${month}/'
);
```

#### Opción A: AWS Console

1. Ir a [Athena Console](https://console.aws.amazon.com/athena/)
2. Seleccionar Workgroup: `ecommerce-datalake-workgroup-dev`
3. Seleccionar Database: `ecommerce-datalake_dev`
4. Ejecutar queries desde `queries/sample_queries.sql`

#### Opción B: AWS CLI

```bash
aws athena start-query-execution \
  --query-string "SELECT year, month, COUNT(*) as total_orders, ROUND(SUM(total_amount),2) as revenue FROM \"ecommerce-datalake_dev\".orders GROUP BY year, month ORDER BY year, month" \
  --work-group ecommerce-datalake-workgroup-dev \
  --region us-east-2
```

## Troubleshooting

### Glue Connection: "Validation for connection properties failed"

La Glue Connection debe ser tipo `NETWORK` (no `JDBC`) cuando se usa solo para VPC networking. Verificar en `modules/glue/main.tf`:
```hcl
connection_type = "NETWORK"
# No usar connection_properties con JDBC_ENFORCE_SSL
```

### Glue Job: "glue:GetConnection action is not authorized"

El rol IAM del Glue Job necesita `glue:GetConnection` para leer la configuración de la VPC Connection:
```json
{ "Effect": "Allow", "Action": ["glue:GetConnection"], "Resource": "*" }
```

### Glue Job: "At least one security group must open all ingress ports"

El security group de la Glue Connection necesita una regla self-referencing para comunicación inter-nodo:
```hcl
ingress {
  from_port = 0
  to_port   = 65535
  protocol  = "tcp"
  self      = true
}
```

### Glue Job: "DescribeRouteTables action is unauthorized"

Glue valida el VPC S3 endpoint inspeccionando las route tables. Agregar al rol:
```json
{ "Effect": "Allow", "Action": ["ec2:DescribeRouteTables"], "Resource": "*" }
```

### Athena: "Database does not exist: ecommerce_datalake_dev"

El nombre de la database tiene guión (`ecommerce-datalake_dev`). Usar backticks en DDL Hive o comillas dobles en queries Trino:
```sql
-- DDL (Hive syntax)
CREATE EXTERNAL TABLE `ecommerce-datalake_dev`.`orders` (...)
-- Queries (Trino syntax)
SELECT * FROM "ecommerce-datalake_dev".orders
```

### Athena: orders devuelve 0 registros

Si la tabla orders fue creada por el Glue Crawler, las particiones pueden no estar registradas. Solución: recrear la tabla con Partition Projection (ver paso 11).

### Athena: "HIVE_BAD_DATA: Field X type INT64 incompatible with varchar"

Los tipos de la tabla DDL no coinciden con el Parquet. Verificar los tipos reales con:
```sql
DESCRIBE "ecommerce-datalake_dev".orders;
```
Usar `bigint` para campos numéricos que en el Parquet son INT64.

### Error: "Access Denied" al subir a S3

Verificar permisos IAM del usuario AWS CLI.

### Glue Job falla (genérico)

Ver logs en CloudWatch:
```bash
aws logs tail /aws-glue/python-jobs/output --follow --region us-east-2
```

### Mensajes en la DLQ

Si hay mensajes en la DLQ, significa que la Lambda falló al procesar un evento S3. Ver logs:
```bash
aws logs tail /aws/lambda/ecommerce-datalake-sqs-glue-trigger-dev --follow --region us-east-2
```

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
