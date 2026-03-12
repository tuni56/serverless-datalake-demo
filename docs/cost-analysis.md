# Análisis de Costos - Data Lake Serverless Demo

## 📊 Resumen Ejecutivo

**Costo estimado para la demo completa**: **$3-5 USD**

Este análisis considera el uso de la capa gratuita de AWS y los costos incrementales para una demo de 2-3 horas con datasets de tamaño moderado.

## 🆓 Capa Gratuita AWS (12 meses)

### Amazon S3
- **5 GB** de almacenamiento estándar
- **20,000** solicitudes GET
- **2,000** solicitudes PUT
- **100 GB** de transferencia de datos salientes

### AWS Glue
- **1 millón** de objetos almacenados en el Data Catalog
- **10 horas** de tiempo de ejecución de Glue ETL (DPU)

### Amazon Athena
- **No tiene capa gratuita**, pero es pay-per-query

## 💵 Desglose de Costos por Servicio (us-east-2)

### 1. Amazon S3

#### Almacenamiento
- **Dataset estimado**: 500 MB raw (CSV) + 200 MB curated (Parquet) = 700 MB
- **Costo**: $0.023 por GB/mes
- **Cálculo**: 0.7 GB × $0.023 = **$0.016/mes**
- **Estado**: ✅ Cubierto por capa gratuita (5 GB)

#### Solicitudes API
- **PUT requests**: ~1,000 (subir archivos, ETL writes)
- **GET requests**: ~5,000 (Crawler, ETL reads, Athena queries)
- **Costo PUT**: $0.005 por 1,000 requests = **$0.005**
- **Costo GET**: $0.0004 por 1,000 requests = **$0.002**
- **Total requests**: **$0.007**
- **Estado**: ✅ Cubierto por capa gratuita

#### Transferencia de Datos
- **Salida**: Mínima (solo consultas Athena a consola)
- **Costo**: **$0**
- **Estado**: ✅ Cubierto por capa gratuita (100 GB)

**Total S3**: **$0** (cubierto por free tier)

---

### 2. AWS Glue

#### Data Catalog
- **Objetos almacenados**: ~10 tablas/particiones
- **Costo**: Primeros 1M objetos gratis
- **Total**: **$0**
- **Estado**: ✅ Cubierto por capa gratuita

#### Glue Crawler
- **Tiempo de ejecución estimado**: 2-3 minutos por crawl × 3 crawls = 9 minutos
- **Costo**: $0.44 por hora de DPU (Data Processing Unit)
- **DPU por defecto**: 2 DPUs
- **Cálculo**: (9/60) horas × 2 DPUs × $0.44 = **$0.13**
- **Estado**: ✅ Cubierto por capa gratuita (10 horas)

#### Glue ETL Job
- **Tiempo de ejecución estimado**: 5-10 minutos
- **DPU asignados**: 2 DPUs (mínimo para Python Shell) o 10 DPUs (Spark)
- **Opción 1 - Python Shell**: (10/60) × 1 DPU × $0.44 = **$0.07**
- **Opción 2 - Spark**: (10/60) × 10 DPUs × $0.44 = **$0.73**
- **Recomendación**: Usar **Python Shell** para datasets pequeños
- **Estado**: ✅ Cubierto por capa gratuita (10 horas)

**Total Glue**: **$0** (cubierto por free tier)

---

### 3. Amazon Athena

#### Queries SQL
- **Costo**: $5 por TB de datos escaneados
- **Dataset curated (Parquet)**: 200 MB
- **Queries estimadas**: 10-15 queries durante la demo
- **Datos escaneados por query**: ~50-100 MB (con particionamiento y Parquet)
- **Total escaneado**: 1 GB (siendo conservadores)
- **Cálculo**: (1/1000) TB × $5 = **$0.005**

**Optimizaciones aplicadas**:
- ✅ Formato Parquet (compresión ~70% vs CSV)
- ✅ Particionamiento por fecha
- ✅ Selección de columnas específicas (no SELECT *)

**Total Athena**: **$0.005** ⚠️ **NO cubierto por free tier**

---

### 4. IAM, CloudWatch Logs

#### IAM
- **Costo**: **$0** (sin cargo)

#### CloudWatch Logs
- **Logs de Glue Jobs**: ~50 MB
- **Costo**: Primeros 5 GB gratis
- **Total**: **$0**
- **Estado**: ✅ Cubierto por capa gratuita

---

### 5. VPC Endpoints (Opcional)

#### Gateway Endpoint (S3)
- **Costo**: **$0** (sin cargo)

#### Interface Endpoint (Glue)
- **Costo**: $0.01 por hora + $0.01 por GB procesado
- **Uso demo**: 3 horas × $0.01 = **$0.03**
- **Datos procesados**: 1 GB × $0.01 = **$0.01**
- **Total**: **$0.04**

**Recomendación para demo**: ⚠️ **Omitir VPC Endpoints** para reducir costos. Mencionar en la charla como best practice para producción.

---

## 📈 Resumen de Costos

| Servicio | Costo Estimado | Cubierto por Free Tier |
|----------|----------------|------------------------|
| S3 Storage | $0.016 | ✅ Sí |
| S3 Requests | $0.007 | ✅ Sí |
| Glue Crawler | $0.13 | ✅ Sí |
| Glue ETL Job | $0.07 | ✅ Sí |
| Athena Queries | $0.005 | ❌ No |
| CloudWatch | $0 | ✅ Sí |
| VPC Endpoints | $0.04 | ❌ Opcional |
| **TOTAL SIN VPC** | **~$0.005** | |
| **TOTAL CON VPC** | **~$0.045** | |

---

## 🎯 Recomendaciones para la Demo

### Configuración Recomendada (Costo: ~$0.01)
1. ✅ **Usar capa gratuita** para S3 y Glue
2. ✅ **Dataset moderado**: 500 MB raw, 200 MB curated
3. ✅ **Glue Python Shell** en lugar de Spark
4. ✅ **Formato Parquet** con compresión Snappy
5. ✅ **Particionamiento** por año/mes
6. ❌ **Omitir VPC Endpoints** (mencionar como best practice)
7. ✅ **Limitar queries Athena** a 10-15 durante la demo

### Optimizaciones Adicionales
- Usar `LIMIT` en queries de prueba
- Particionar datos por `order_date` (año/mes)
- Comprimir archivos Parquet con Snappy
- Eliminar recursos después de la demo con `terraform destroy`

---

## 🧹 Cleanup Post-Demo

Para evitar costos recurrentes:

```bash
# 1. Eliminar datos de S3
aws s3 rm s3://ecommerce-datalake-raw-<account-id> --recursive
aws s3 rm s3://ecommerce-datalake-curated-<account-id> --recursive

# 2. Destruir infraestructura Terraform
cd terraform/environments/dev
terraform destroy --auto-approve

# 3. Verificar Glue Data Catalog
aws glue get-databases --region us-east-2
aws glue delete-database --name ecommerce_db --region us-east-2
```

**Costo de retención si olvidas limpiar**: ~$0.50/mes (principalmente S3 storage)

---

## 💡 Costos en Producción (Estimación)

Para un caso real con 100 GB de datos nuevos por mes:

| Servicio | Costo Mensual Estimado |
|----------|------------------------|
| S3 Storage (500 GB) | $11.50 |
| Glue Crawlers (diario) | $13.20 |
| Glue ETL Jobs (diario) | $66.00 |
| Athena Queries (100 GB escaneados) | $0.50 |
| **TOTAL** | **~$91.20/mes** |

**Nota**: Estos costos escalan linealmente con el volumen de datos y frecuencia de procesamiento.

---

## 📚 Referencias

- [AWS Pricing Calculator](https://calculator.aws/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [Glue Pricing](https://aws.amazon.com/glue/pricing/)
- [Athena Pricing](https://aws.amazon.com/athena/pricing/)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

**Última actualización**: Marzo 2026  
**Región**: us-east-2 (Ohio)
