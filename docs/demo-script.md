# Demo Script - Charla User Group La Paz

## Preparación Pre-Demo (30 min antes)

### 1. Verificar Prerrequisitos
```bash
# Verificar AWS CLI
aws --version
aws sts get-caller-identity

# Verificar Terraform
terraform --version

# Verificar Python
python3 --version
```

### 2. Generar Datos
```bash
cd data-generator
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python generate_ecommerce_data.py
ls -lh output/
```

### 3. Desplegar Infraestructura
```bash
cd ../terraform/environments/dev
terraform init
terraform plan
terraform apply -auto-approve
```

**⏱ Tiempo: ~3 minutos**

### 4. Subir Datos a S3
```bash
RAW_BUCKET=$(terraform output -raw raw_bucket_name)
SCRIPTS_BUCKET=$(terraform output -raw scripts_bucket_name)

cd ../../..
aws s3 cp data-generator/output/ s3://$RAW_BUCKET/ --recursive
aws s3 cp glue-jobs/transform_raw_to_curated.py s3://$SCRIPTS_BUCKET/
```

---

## Durante la Demo (45 min)

### Introducción (5 min)

**Slide 1: Problema**
> "En muchas organizaciones, los datos se acumulan rápidamente pero analizarlos se vuelve lento y costoso."

**Slide 2: Solución**
> "Hoy vamos a construir un Data Lake serverless que transforma datos crudos en información lista para análisis, sin administrar servidores."

**Slide 3: Arquitectura**
> Mostrar diagrama de arquitectura (docs/architecture.md)

### Parte 1: Mostrar Datos Raw (5 min)

```bash
# Mostrar estructura de datos
aws s3 ls s3://$RAW_BUCKET/ --recursive

# Descargar y mostrar sample
aws s3 cp s3://$RAW_BUCKET/orders/orders.csv - | head -20

# Mostrar tamaño
aws s3 ls s3://$RAW_BUCKET/ --recursive --summarize
```

**Puntos clave**:
- Datos en formato CSV (legible pero ineficiente)
- ~50 MB de datos
- Sin estructura, sin índices

### Parte 2: Glue Crawler - Schema Discovery (10 min)

```bash
# Ejecutar Crawler
aws glue start-crawler --name ecommerce-datalake-raw-crawler-dev --region us-east-2

# Monitorear estado
watch -n 5 'aws glue get-crawler --name ecommerce-datalake-raw-crawler-dev --region us-east-2 --query "Crawler.State"'
```

**Mientras espera (2-3 min)**:
- Explicar qué hace el Crawler
- Descubrimiento automático de schema
- Creación de tablas en Data Catalog
- Compatible con Hive Metastore

```bash
# Ver tablas creadas
aws glue get-tables --database-name ecommerce-datalake-dev --region us-east-2

# Ver schema de orders
aws glue get-table --database-name ecommerce-datalake-dev --name orders --region us-east-2 --query 'Table.StorageDescriptor.Columns'
```

**Puntos clave**:
- Schema inferido automáticamente
- Metadatos centralizados
- Sin código, sin configuración manual

### Parte 3: Consultar con Athena (Raw) (5 min)

**Abrir Athena Console**:
1. Seleccionar workgroup: `ecommerce-datalake-workgroup-dev`
2. Seleccionar database: `ecommerce-datalake-dev`

```sql
-- Query 1: Contar orders
SELECT COUNT(*) as total_orders FROM orders;
```

**Mostrar**:
- Tiempo de ejecución
- Datos escaneados (importante para costos)
- Resultado

```sql
-- Query 2: Revenue por status
SELECT 
    status,
    COUNT(*) as order_count,
    SUM(total_amount) as revenue
FROM orders
GROUP BY status
ORDER BY revenue DESC;
```

**Puntos clave**:
- Consultas SQL estándar
- Sin infraestructura
- Pay-per-query ($5/TB escaneado)
- Formato CSV = escanea todo el archivo

### Parte 4: Glue ETL Job - Transformación (10 min)

```bash
# Mostrar script de transformación
cat glue-jobs/transform_raw_to_curated.py
```

**Explicar transformaciones**:
- CSV → Parquet (formato columnar)
- Compresión Snappy
- Particionamiento por año/mes
- Data quality checks

```bash
# Ejecutar Job
aws glue start-job-run --job-name ecommerce-datalake-transform-dev --region us-east-2

# Obtener Job Run ID
JOB_RUN_ID=$(aws glue get-job-runs --job-name ecommerce-datalake-transform-dev --region us-east-2 --query 'JobRuns[0].Id' --output text)

# Monitorear
watch -n 5 "aws glue get-job-run --job-name ecommerce-datalake-transform-dev --run-id $JOB_RUN_ID --region us-east-2 --query 'JobRun.JobRunState'"
```

**Mientras espera (5-10 min)**:
- Explicar ventajas de Parquet
- Compresión: 70-80% reducción
- Columnar: lee solo columnas necesarias
- Particionamiento: partition pruning

```bash
# Ver datos transformados
CURATED_BUCKET=$(terraform output -raw curated_bucket_name)
aws s3 ls s3://$CURATED_BUCKET/ --recursive

# Comparar tamaños
echo "Raw (CSV):"
aws s3 ls s3://$RAW_BUCKET/ --recursive --summarize | grep "Total Size"

echo "Curated (Parquet):"
aws s3 ls s3://$CURATED_BUCKET/ --recursive --summarize | grep "Total Size"
```

**Puntos clave**:
- Reducción de ~70% en tamaño
- Datos particionados por fecha
- Optimizado para analytics

### Parte 5: Crawler Curated + Athena Optimizado (10 min)

```bash
# Ejecutar Crawler curated
aws glue start-crawler --name ecommerce-datalake-curated-crawler-dev --region us-east-2

# Esperar ~2 min

# Ver particiones descubiertas
aws glue get-partitions --database-name ecommerce-datalake-dev --table-name orders --region us-east-2
```

**Volver a Athena Console**:

```sql
-- Query 3: Misma query pero en Parquet
SELECT COUNT(*) as total_orders FROM orders;
```

**Comparar**:
- Tiempo de ejecución (más rápido)
- Datos escaneados (mucho menos)
- Costo (70-80% menor)

```sql
-- Query 4: Análisis con particionamiento
SELECT 
    year,
    month,
    COUNT(*) as total_orders,
    SUM(total_amount) as revenue,
    AVG(total_amount) as avg_ticket
FROM orders
WHERE year = 2025 AND month = 3
GROUP BY year, month;
```

**Mostrar**:
- Solo escanea partición específica
- Costo mínimo
- Performance excelente

```sql
-- Query 5: Join entre tablas
SELECT 
    p.category,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY revenue DESC
LIMIT 10;
```

**Puntos clave**:
- Joins funcionan perfectamente
- Formato columnar = solo lee columnas necesarias
- Escalable a TB/PB de datos

### Conclusión (5 min)

**Recapitular**:
1. ✅ Datos raw en S3 (CSV)
2. ✅ Schema discovery con Glue Crawler
3. ✅ Transformación con Glue ETL (CSV → Parquet)
4. ✅ Consultas optimizadas con Athena
5. ✅ Todo serverless, sin servidores que administrar

**Beneficios**:
- 💰 Costo: < $5 para esta demo
- ⚡ Performance: 10-100x más rápido con Parquet
- 🔒 Seguridad: Encryption, IAM, bucket policies
- 📈 Escalabilidad: GB a PB sin cambios arquitectónicos
- 🛠 Operaciones: Cero servidores que administrar

**Próximos pasos**:
- Automatización con Glue Triggers
- Governance con Lake Formation
- Visualización con QuickSight
- ML con SageMaker

---

## Post-Demo: Cleanup

```bash
# Ejecutar script de cleanup
./scripts/cleanup.sh

# O manualmente
cd terraform/environments/dev
terraform destroy -auto-approve
```

---

## Tips para la Demo

### Antes de empezar
- ✅ Tener AWS Console abierta en tabs separadas (S3, Glue, Athena)
- ✅ Terminal con font grande y colores
- ✅ Tener queries SQL preparadas en editor
- ✅ Verificar conectividad a internet
- ✅ Tener backup de screenshots por si algo falla

### Durante la demo
- 🎤 Hablar mientras esperan los procesos
- 📊 Mostrar diagramas de arquitectura
- 💡 Explicar decisiones técnicas (por qué Parquet, por qué serverless)
- ❓ Invitar preguntas durante la demo
- 🐛 Si algo falla, tener plan B (screenshots, videos)

### Preguntas frecuentes esperadas

**P: ¿Cuánto cuesta en producción?**
R: Depende del volumen. Para 100 GB/mes: ~$90/mes. Ver docs/cost-analysis.md

**P: ¿Cómo se compara con Redshift/Snowflake?**
R: Athena es mejor para queries ad-hoc. Redshift para queries frecuentes y complejas.

**P: ¿Soporta streaming?**
R: Sí, con Kinesis Firehose puedes ingestar datos en tiempo real.

**P: ¿Cómo se automatiza?**
R: Glue Triggers, EventBridge, Step Functions.

**P: ¿Qué pasa con datos sensibles?**
R: Lake Formation para permisos granulares, KMS para encryption avanzada.

---

## Recursos para Compartir

- 📁 Repositorio GitHub: [link]
- 📄 Documentación: docs/
- 💰 Análisis de costos: docs/cost-analysis.md
- 🏗 Arquitectura: docs/architecture.md
- 🚀 Deployment: docs/deployment-guide.md

**Contacto**:
- AWS User Group La Paz
- [Tu email/LinkedIn]
