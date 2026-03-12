# Serverless Data Lake en AWS - E-commerce Analytics

Demo para el User Group de La Paz: Arquitectura de Data Lake Serverless utilizando S3, Glue y Athena para análisis de datos de e-commerce.

## 📋 Descripción del Proyecto

Este proyecto implementa un Data Lake serverless en AWS siguiendo las mejores prácticas del Well-Architected Framework, específicamente enfocado en los pilares de:

- **Excelencia Operacional**: IaC con Terraform, versionamiento GitFlow
- **Seguridad**: Encryption at rest/in transit, IAM roles con least privilege, VPC endpoints
- **Confiabilidad**: Servicios serverless administrados por AWS
- **Eficiencia de Rendimiento**: Formato Parquet columnar, particionamiento de datos
- **Optimización de Costos**: Pay-per-query con Athena, sin infraestructura permanente

## 🏗️ Arquitectura

```
┌─────────────────┐
│  Raw Data (CSV) │
│   S3 Bucket     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Glue Crawler   │
│  (Schema Disc.) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Glue ETL Job  │
│ (Transform to   │
│    Parquet)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Curated Data    │
│  (Parquet)      │
│   S3 Bucket     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Athena Queries  │
│  (SQL Analysis) │
└─────────────────┘
```

## 🎯 Caso de Uso: E-commerce Analytics

Análisis de transacciones de una plataforma de e-commerce con tres datasets principales:

1. **Orders**: Pedidos realizados (order_id, customer_id, order_date, total_amount, status)
2. **Customers**: Información de clientes (customer_id, name, email, country, registration_date)
3. **Products**: Catálogo de productos (product_id, name, category, price, stock)

### Preguntas de Negocio a Responder

- ¿Cuáles son las ventas totales por mes/trimestre?
- ¿Qué categorías de productos generan más ingresos?
- ¿Cuál es el ticket promedio por cliente?
- ¿Qué países tienen mayor volumen de compras?
- ¿Cuál es la tasa de conversión por categoría?

## 📁 Estructura del Proyecto

```
.
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   └── prod/
│   ├── modules/
│   │   ├── iam/
│   │   ├── s3/
│   │   ├── glue/
│   │   └── athena/
│   └── backend.tf
├── glue-jobs/
│   └── transform_raw_to_curated.py
├── data-generator/
│   └── generate_ecommerce_data.py
├── queries/
│   └── sample_queries.sql
├── docs/
│   ├── architecture.md
│   ├── cost-analysis.md
│   └── deployment-guide.md
└── scripts/
    ├── setup.sh
    └── cleanup.sh
```

## 🔐 Seguridad

- **Encryption at Rest**: S3 buckets con SSE-S3
- **Encryption in Transit**: TLS 1.2+ obligatorio
- **IAM Roles**: Least privilege para Glue, Athena
- **VPC Endpoints**: Acceso privado a S3 y Glue (opcional para demo)
- **Bucket Policies**: Deny HTTP, enforce encryption

## 🚀 Deployment

### Prerrequisitos

- AWS CLI configurado
- Terraform >= 1.5
- Python 3.9+
- Credenciales AWS con permisos administrativos

### Pasos

```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd serverless-datalake-demo

# 2. Generar datos de prueba
cd data-generator
python generate_ecommerce_data.py

# 3. Desplegar infraestructura
cd ../terraform/environments/dev
terraform init
terraform plan
terraform apply

# 4. Ejecutar Glue Crawler
aws glue start-crawler --name ecommerce-raw-crawler --region us-east-2

# 5. Ejecutar Glue ETL Job
aws glue start-job-run --job-name transform-raw-to-curated --region us-east-2

# 6. Consultar con Athena
# Ver queries en queries/sample_queries.sql
```

## 💰 Análisis de Costos

Ver [docs/cost-analysis.md](docs/cost-analysis.md) para detalles completos.

**Estimación para la demo**: < $5 USD

## 🌿 Estrategia de Branching (GitFlow)

- `main`: Producción
- `develop`: Integración
- `feature/*`: Nuevas funcionalidades
- `release/*`: Preparación de releases
- `hotfix/*`: Correcciones urgentes

## 📚 Recursos

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Glue Best Practices](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)
- [Athena Performance Tuning](https://docs.aws.amazon.com/athena/latest/ug/performance-tuning.html)

## 👥 Autor

Demo preparada para el AWS User Group La Paz - Marzo 2026

## 📄 Licencia

MIT
