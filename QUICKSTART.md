# Guía Rápida de Uso del Repositorio

## Estructura de Ramas

```bash
# Ver todas las ramas
git branch -a

# Ramas principales:
# - main: código en producción (v1.0.0)
# - develop: integración de desarrollo
# - feature/*: funcionalidades en desarrollo
```

## Quick Start (5 minutos)

### 1. Clonar y Explorar

```bash
git clone <repo-url>
cd serverless-datalake-demo

# Ver estructura
tree -L 2

# Ver documentación
ls docs/
```

### 2. Generar Datos

```bash
cd data-generator
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
python generate_ecommerce_data.py
```

### 3. Desplegar con Script Automatizado

```bash
cd ..
./scripts/setup.sh
```

O manualmente:

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

### 4. Ejecutar Pipeline

```bash
# 1. Crawler
aws glue start-crawler --name ecommerce-datalake-raw-crawler-dev --region us-east-2

# 2. ETL Job (esperar a que termine el crawler)
aws glue start-job-run --job-name ecommerce-datalake-transform-dev --region us-east-2

# 3. Crawler curated (esperar a que termine el job)
aws glue start-crawler --name ecommerce-datalake-curated-crawler-dev --region us-east-2
```

### 5. Consultar con Athena

Abrir [Athena Console](https://console.aws.amazon.com/athena/) y ejecutar queries de `queries/sample_queries.sql`

### 6. Cleanup

```bash
./scripts/cleanup.sh
```

## Documentación

| Documento | Descripción |
|-----------|-------------|
| [README.md](README.md) | Visión general del proyecto |
| [architecture.md](docs/architecture.md) | Arquitectura detallada |
| [cost-analysis.md](docs/cost-analysis.md) | Análisis de costos |
| [deployment-guide.md](docs/deployment-guide.md) | Guía de deployment paso a paso |
| [demo-script.md](docs/demo-script.md) | Script para la presentación |
| [gitflow-strategy.md](docs/gitflow-strategy.md) | Estrategia de branching |

## Comandos Útiles

```bash
# Ver outputs de Terraform
cd terraform/environments/dev
terraform output

# Ver logs de Glue Job
aws logs tail /aws-glue/jobs/output --follow --region us-east-2

# Listar objetos en S3
aws s3 ls s3://BUCKET-NAME --recursive

# Ver tablas en Glue Catalog
aws glue get-tables --database-name ecommerce-datalake-dev --region us-east-2

# Ejecutar query en Athena (CLI)
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) FROM orders" \
  --query-execution-context Database=ecommerce-datalake-dev \
  --result-configuration OutputLocation=s3://RESULTS-BUCKET/ \
  --region us-east-2
```

## Troubleshooting

### Error: "Access Denied" en S3
```bash
# Verificar permisos
aws sts get-caller-identity
aws iam get-user
```

### Glue Job falla
```bash
# Ver logs
aws logs tail /aws-glue/jobs/error --region us-east-2
```

### Terraform apply falla
```bash
# Limpiar estado
terraform refresh
terraform plan
```

## Costos Estimados

- **Demo completa**: < $5 USD
- **Producción (100 GB/mes)**: ~$90/mes

Ver [cost-analysis.md](docs/cost-analysis.md) para detalles.

## Soporte

- Issues: [GitHub Issues]
- Documentación: `docs/`
- AWS User Group La Paz

## Licencia

MIT - Ver [LICENSE](LICENSE)
