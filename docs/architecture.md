# Arquitectura del Data Lake Serverless

## Visión General

Este proyecto implementa un Data Lake serverless en AWS siguiendo una arquitectura de medallón (Bronze/Silver/Gold), adaptada a dos capas: **Raw** y **Curated**.

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                             │
│                    (CSV Files - E-commerce)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      RAW LAYER (Bronze)                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  S3 Bucket: ecommerce-datalake-raw-{account-id}          │   │
│  │  - Format: CSV                                            │   │
│  │  - Encryption: SSE-S3                                     │   │
│  │  - Versioning: Enabled                                    │   │
│  │  - Structure:                                             │   │
│  │    └── customers/customers.csv                            │   │
│  │    └── products/products.csv                              │   │
│  │    └── orders/orders.csv                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SCHEMA DISCOVERY                              │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  AWS Glue Crawler (Raw)                                   │   │
│  │  - Scans S3 raw bucket                                    │   │
│  │  - Infers schema automatically                            │   │
│  │  - Creates/updates tables in Data Catalog                │   │
│  │  - DPU: 2 (default)                                       │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA CATALOG                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  AWS Glue Data Catalog                                    │   │
│  │  Database: ecommerce-datalake-dev                         │   │
│  │  Tables:                                                  │   │
│  │    - customers (schema metadata)                          │   │
│  │    - products (schema metadata)                           │   │
│  │    - orders (schema metadata)                             │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ETL TRANSFORMATION                            │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  AWS Glue ETL Job (Python Shell)                          │   │
│  │  - Reads CSV from raw bucket                              │   │
│  │  - Transforms data:                                       │   │
│  │    • Converts to Parquet format                           │   │
│  │    • Applies Snappy compression                           │   │
│  │    • Partitions orders by year/month                      │   │
│  │    • Data quality checks                                  │   │
│  │  - Writes to curated bucket                               │   │
│  │  - DPU: 1 (Python Shell)                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   CURATED LAYER (Silver/Gold)                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  S3 Bucket: ecommerce-datalake-curated-{account-id}      │   │
│  │  - Format: Parquet (columnar)                             │   │
│  │  - Compression: Snappy                                    │   │
│  │  - Encryption: SSE-S3                                     │   │
│  │  - Versioning: Enabled                                    │   │
│  │  - Structure:                                             │   │
│  │    └── customers/customers.parquet                        │   │
│  │    └── products/products.parquet                          │   │
│  │    └── orders/                                            │   │
│  │        └── year=2025/month=01/*.parquet                   │   │
│  │        └── year=2025/month=02/*.parquet                   │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SCHEMA DISCOVERY (Curated)                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  AWS Glue Crawler (Curated)                               │   │
│  │  - Scans S3 curated bucket                                │   │
│  │  - Discovers Parquet schema and partitions               │   │
│  │  - Updates Data Catalog                                   │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    QUERY & ANALYTICS                             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Amazon Athena                                            │   │
│  │  - Serverless SQL queries                                 │   │
│  │  - Queries Parquet files directly on S3                  │   │
│  │  - Workgroup: ecommerce-datalake-workgroup-dev           │   │
│  │  - Results stored in S3 (encrypted)                       │   │
│  │  - Pricing: $5 per TB scanned                            │   │
│  └──────────────────────────────────────────────────────────┘   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                         CONSUMERS                                │
│  - Business Intelligence (QuickSight)                            │
│  - Data Scientists (SageMaker)                                   │
│  - Applications (API Gateway + Lambda)                           │
│  - Analysts (Athena Console)                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Componentes Principales

### 1. Amazon S3 (Storage Layer)

**Raw Bucket**:
- Almacena datos en formato original (CSV)
- Inmutable: los datos no se modifican
- Versionamiento habilitado para auditoría
- Encryption at rest con SSE-S3
- Lifecycle policy: retención según compliance

**Curated Bucket**:
- Almacena datos transformados (Parquet)
- Optimizado para queries analíticas
- Particionado para mejorar performance
- Compresión Snappy (balance entre compresión y velocidad)

**Scripts Bucket**:
- Almacena scripts de Glue Jobs
- Versionamiento para control de cambios

**Athena Results Bucket**:
- Almacena resultados de queries
- Lifecycle policy: eliminar después de 7 días

### 2. AWS Glue (ETL & Catalog)

**Glue Data Catalog**:
- Metastore centralizado (compatible con Hive)
- Almacena schemas, particiones, estadísticas
- Integrado con Athena, EMR, Redshift Spectrum

**Glue Crawlers**:
- Descubrimiento automático de schemas
- Detección de particiones
- Actualización incremental de metadatos
- Scheduler: on-demand o programado

**Glue ETL Job**:
- Python Shell (1 DPU) para datasets pequeños
- Transformaciones:
  - CSV → Parquet
  - Particionamiento temporal
  - Data quality checks
  - Deduplicación
- Job Bookmarks: procesa solo datos nuevos

### 3. Amazon Athena (Query Engine)

- Motor: Trino (Athena engine v3)
- Serverless: sin infraestructura que administrar
- Pricing: pay-per-query ($5/TB escaneado)
- Partition Projection: descubrimiento automático de particiones sin MSCK REPAIR
- Optimizaciones:
  - Formato columnar (Parquet)
  - Compresión
  - Particionamiento con projection (year/month)
  - Selección de columnas específicas

### 4. VPC & Networking (Security Layer)

**VPC** (`10.0.0.0/16`):
- 2 subnets privadas (us-east-2a, us-east-2b) para alta disponibilidad
- Sin NAT Gateway ni Internet Gateway — tráfico aislado
- Route table privada asociada a ambas subnets

**VPC Endpoints**:
- **S3 Gateway Endpoint**: Tráfico a S3 sin salir a internet, asociado a la route table privada
- **Glue Interface Endpoint**: Tráfico al API de Glue vía PrivateLink, desplegado en ambas subnets

**Security Group** (`vpc-endpoints-sg`):
- Ingress: HTTPS (443) desde el CIDR de la VPC
- Ingress: All TCP (0-65535) self-referencing — requerido por Glue para comunicación inter-nodo
- Egress: All outbound

**Glue Connection** (tipo `NETWORK`):
- Asociada a subnet privada + security group
- Permite que el Glue Job ejecute dentro de la VPC
- Accede a S3 vía Gateway Endpoint y al Glue Catalog vía Interface Endpoint

### 5. IAM (Security)

**Roles creados**:

1. **Glue Crawler Role**:
   - Permisos: S3 read, Glue Data Catalog write
   - Principio de least privilege

2. **Glue Job Role**:
   - Permisos: S3 read/write, Glue Data Catalog read, `glue:GetConnection`
   - EC2 networking: `CreateNetworkInterface`, `DeleteNetworkInterface`, `Describe*` (subnets, SGs, VPC, route tables, endpoints)
   - EC2 tagging: `CreateTags`/`DeleteTags` en ENIs (condicionado a tag `aws-glue-service-resource`)
   - Acceso a CloudWatch Logs

3. **Lambda SQS Trigger Role**:
   - Permisos: SQS read/delete, Glue StartJobRun, CloudWatch Logs

**Políticas de seguridad**:
- Deny HTTP (solo HTTPS)
- Encryption obligatoria
- Block public access en todos los buckets

## Flujo de Datos

1. **Ingesta**: Datos CSV subidos a S3 raw bucket
2. **Evento**: S3 envía notificación a cola SQS (`s3:ObjectCreated:*` en `orders/`)
3. **Trigger**: Lambda consume el mensaje SQS y ejecuta `glue:StartJobRun`
4. **Transform**: Glue Job (dentro de la VPC) lee CSV, transforma a Parquet, escribe a curated bucket
   - Accede a S3 vía VPC Gateway Endpoint
   - Accede al Glue Catalog vía VPC Interface Endpoint
5. **Catalog**: Glue Crawler actualiza metadatos de datos curados; tablas con Partition Projection no requieren crawler
6. **Query**: Athena consulta Parquet files usando metadatos del Catalog
7. **Consume**: Usuarios/aplicaciones consumen resultados
8. **Observabilidad**: CloudWatch Alarms monitorean DLQ y Glue Job failures → SNS → Email

## Decisiones de Arquitectura

### ¿Por qué Parquet?

- **Columnar**: Lee solo columnas necesarias (vs row-based CSV)
- **Compresión**: 70-80% reducción de tamaño vs CSV
- **Performance**: 10-100x más rápido en queries analíticas
- **Schema evolution**: Soporta cambios de schema
- **Compatibilidad**: Estándar en ecosistema big data

### ¿Por qué Particionamiento?

- **Partition pruning**: Athena escanea solo particiones relevantes
- **Costo**: Reduce datos escaneados = menor costo
- **Performance**: Queries más rápidas
- **Estrategia**: Particionar por columnas de filtro frecuente (fecha)

### ¿Por qué Serverless?

- **No servers**: Sin EC2, EMR clusters que administrar
- **Auto-scaling**: Escala automáticamente con la carga
- **Pay-per-use**: Solo pagas por lo que usas
- **Mantenimiento**: AWS gestiona patches, updates
- **Time-to-market**: Deploy en minutos, no días

### ¿Por qué dos capas (Raw + Curated)?

- **Raw**: Preserva datos originales (auditoría, reprocessing)
- **Curated**: Optimizado para analytics (performance, costo)
- **Flexibilidad**: Permite múltiples transformaciones desde raw
- **Compliance**: Separación de datos sensibles vs procesados

## Well-Architected Framework

### Excelencia Operacional
- ✅ IaC con Terraform (reproducible, versionado)
- ✅ CloudWatch Logs para monitoreo
- ✅ CloudWatch Alarms + SNS para alertas proactivas
- ✅ CloudWatch Dashboard para visibilidad del pipeline
- ✅ Glue Job Bookmarks para idempotencia
- ✅ DLQ para mensajes fallidos (retención 14 días)

### Seguridad
- ✅ Encryption at rest (SSE-S3)
- ✅ Encryption in transit (TLS)
- ✅ IAM roles con least privilege
- ✅ VPC con subnets privadas (2 AZs)
- ✅ VPC Endpoints: S3 (Gateway) + Glue (Interface) — sin tráfico a internet
- ✅ Glue Connection tipo NETWORK con SG self-referencing
- ✅ Bucket policies restrictivas
- ✅ Versionamiento habilitado
- ✅ Public Access Block en todos los buckets

### Confiabilidad
- ✅ Servicios serverless administrados por AWS
- ✅ S3 durabilidad 99.999999999%
- ✅ Versionamiento para recuperación de datos
- ✅ Multi-AZ por defecto

### Eficiencia de Rendimiento
- ✅ Formato Parquet columnar
- ✅ Compresión Snappy
- ✅ Particionamiento por fecha
- ✅ Glue Python Shell (1 DPU) para datasets pequeños

### Optimización de Costos
- ✅ Pay-per-query (Athena)
- ✅ Sin infraestructura permanente
- ✅ Lifecycle policies en S3
- ✅ Formato Parquet reduce escaneo de datos
- ✅ Capa gratuita de AWS

### Sostenibilidad
- ✅ Serverless = menor huella de carbono
- ✅ Compresión reduce almacenamiento
- ✅ Recursos efímeros (no siempre activos)

## Escalabilidad

Este diseño escala de GB a PB sin cambios arquitectónicos:

- **S3**: Almacenamiento ilimitado
- **Glue**: Auto-scaling de DPUs
- **Athena**: Queries paralelas automáticas
- **Data Catalog**: Millones de tablas/particiones

## Limitaciones y Consideraciones

1. **Athena**:
   - Límite: 100 queries concurrentes por cuenta
   - Timeout: 30 minutos por query
   - Resultado máximo: 100 GB

2. **Glue**:
   - Python Shell: 1 DPU (16 GB RAM)
   - Para datasets grandes (>10 GB), usar Spark (10+ DPUs)

3. **S3**:
   - Consistencia eventual en listados (raro)
   - Costo de transferencia entre regiones

## Extensiones Futuras

1. **Automatización**: Glue Triggers o EventBridge para ETL automático
2. **Data Quality**: AWS Glue Data Quality rules
3. **Governance**: AWS Lake Formation para permisos granulares
4. **Streaming**: Kinesis Firehose para ingesta en tiempo real
5. **ML**: SageMaker para modelos predictivos
6. **BI**: QuickSight para dashboards
7. **Cataloging**: AWS Glue DataBrew para data profiling
