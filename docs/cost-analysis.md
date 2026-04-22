# Análisis de Costos - Data Lake Serverless Demo

## 📊 Resumen Ejecutivo

**Costo estimado para la demo completa (2-3 horas)**: **< $5 USD**

Este análisis considera el uso de la capa gratuita de AWS y los costos incrementales para una demo con datasets de tamaño moderado (~3 MB CSV).

## 🆓 Capa Gratuita AWS (12 meses)

### Amazon S3
- **5 GB** de almacenamiento estándar
- **20,000** solicitudes GET
- **2,000** solicitudes PUT

### AWS Glue
- **1 millón** de objetos almacenados en el Data Catalog
- **10 horas** de tiempo de ejecución de Glue ETL (DPU)

### AWS Lambda
- **1 millón** de solicitudes/mes
- **400,000 GB-segundo** de cómputo/mes

### Amazon SQS
- **1 millón** de solicitudes/mes

### Amazon SNS
- **1,000** notificaciones email/mes

### Amazon Athena
- **No tiene capa gratuita**, pay-per-query

### Amazon QuickSight
- **No tiene capa gratuita** (30 días de trial para cuentas nuevas)

## 💵 Desglose de Costos por Servicio (us-east-2)

### 1. Amazon S3

| Concepto | Detalle | Costo |
|---|---|---|
| Almacenamiento | ~3 MB raw + ~1.5 MB curated = ~5 MB | $0.00 |
| PUT requests | ~100 (uploads, ETL writes) | $0.00 |
| GET requests | ~2,000 (Crawlers, ETL, Athena) | $0.00 |

**Total S3**: **$0.00** ✅ Cubierto por free tier

### 2. AWS Glue

| Concepto | Detalle | Costo |
|---|---|---|
| Data Catalog | ~15 tablas/particiones | $0.00 |
| Crawler (x2) | ~3 min × 2 DPU × $0.44/hr = $0.09 por crawl | $0.18 |
| ETL Job (Python Shell) | ~1 min × 1 DPU × $0.44/hr | $0.01 |

**Total Glue**: **$0.19** ✅ Cubierto por free tier (10 horas)

### 3. Amazon Athena

| Concepto | Detalle | Costo |
|---|---|---|
| Queries SQL | ~15 queries × ~50 MB escaneados = ~750 MB | $0.004 |

Optimizaciones aplicadas: Parquet (~75% menos escaneo vs CSV), particionamiento por year/month.

**Total Athena**: **$0.004** ❌ No tiene free tier (pero es despreciable)

### 4. AWS Lambda

| Concepto | Detalle | Costo |
|---|---|---|
| Invocaciones | ~5 invocaciones | $0.00 |
| Duración | ~5 seg × 128 MB | $0.00 |

**Total Lambda**: **$0.00** ✅ Cubierto por free tier

### 5. Amazon SQS

| Concepto | Detalle | Costo |
|---|---|---|
| Cola principal | ~10 mensajes | $0.00 |
| DLQ | 0 mensajes (idealmente) | $0.00 |

**Total SQS**: **$0.00** ✅ Cubierto por free tier

### 6. VPC Endpoints

| Concepto | Detalle | Costo |
|---|---|---|
| S3 Gateway Endpoint | Sin cargo | $0.00 |
| Glue Interface Endpoint | $0.01/hr × 2 AZs × 3 hrs | $0.06 |
| Datos procesados | ~50 MB × $0.01/GB | $0.001 |

**Total VPC Endpoints**: **$0.06** ❌ No tiene free tier

### 7. Amazon SNS + CloudWatch

| Concepto | Detalle | Costo |
|---|---|---|
| SNS Topic + suscripción email | ~2 notificaciones | $0.00 |
| CloudWatch Alarms (2) | $0.10/alarma/mes (prorrateado) | $0.01 |
| CloudWatch Dashboard | $3.00/mes (prorrateado a 3 hrs) | $0.01 |

**Total Observabilidad**: **$0.02** (parcialmente cubierto por free tier)

### 8. Amazon QuickSight

| Concepto | Detalle | Costo |
|---|---|---|
| Enterprise (1 autor) | $24/mes (prorrateado a 3 hrs) | ~$0.10 |
| Queries DIRECT_QUERY | Sin cargo adicional (usa Athena) | $0.00 |

**Nota**: Si la cuenta es nueva, los primeros 30 días son trial gratuito.

**Total QuickSight**: **$0.00 - $0.10** (depende del trial)

---

## 📈 Resumen de Costos - Demo

| Servicio | Costo | Free Tier |
|---|---|---|
| S3 (storage + requests) | $0.00 | ✅ |
| Glue (Crawlers + ETL) | $0.19 | ✅ |
| Athena (queries) | $0.004 | ❌ |
| Lambda | $0.00 | ✅ |
| SQS (cola + DLQ) | $0.00 | ✅ |
| VPC Endpoint (Glue Interface) | $0.06 | ❌ |
| Observabilidad (CW + SNS) | $0.02 | Parcial |
| QuickSight | $0.00 - $0.10 | Trial 30d |
| **TOTAL** | **~$0.08 - $0.37** | |

> **Con free tier activo y trial de QuickSight: ~$0.08**
> **Sin free tier: ~$0.37**
> **Costo máximo conservador: < $1 USD**

---

## 💡 ¿Por qué tan barato?

Las decisiones de arquitectura impactan directamente en costos:

| Decisión | Ahorro |
|---|---|
| **Python Shell** (1 DPU) vs Spark (10 DPU) | 10x menos en Glue |
| **Parquet** vs CSV | 70-80% menos escaneo en Athena |
| **Particionamiento** por year/month | Partition pruning reduce escaneo |
| **S3 Gateway Endpoint** vs NAT Gateway | $0 vs ~$32/mes |
| **Serverless** (todo) | $0 cuando no se usa |

---

## 💰 Costos en Producción (Estimación)

Para un caso real con **100 GB de datos nuevos por mes**, queries diarias:

| Servicio | Costo Mensual |
|---|---|
| S3 Storage (500 GB acumulado) | $11.50 |
| Glue Crawlers (diario, 2 DPU) | $13.20 |
| Glue ETL Jobs (diario, Python Shell) | $6.60 |
| Glue ETL Jobs (diario, Spark 10 DPU) | $66.00 |
| Athena (100 GB escaneados/mes) | $0.50 |
| VPC Endpoint Glue (24/7, 2 AZs) | $14.40 |
| Lambda + SQS | $0.00 (free tier) |
| CloudWatch (alarms + dashboard) | $3.20 |
| QuickSight (1 autor) | $24.00 |
| **TOTAL (Python Shell)** | **~$73/mes** |
| **TOTAL (Spark)** | **~$133/mes** |

> **Nota**: El VPC Endpoint de Glue ($14.40/mes) es el costo fijo más significativo en producción. Si el Glue Job corre pocas veces al día, considerar crear/destruir el endpoint con el job (tradeoff: complejidad vs costo).

---

## 🧹 Cleanup Post-Demo

Para evitar costos recurrentes:

```bash
# 1. Destruir toda la infraestructura
cd terraform/environments/dev
terraform destroy --auto-approve

# 2. Cancelar QuickSight (si no se necesita)
aws quicksight update-account-settings \
  --aws-account-id ACCOUNT_ID \
  --default-namespace default \
  --no-termination-protection-enabled
aws quicksight delete-account-subscription \
  --aws-account-id ACCOUNT_ID

# 3. Verificar que no queden recursos
aws s3 ls | grep ecommerce-datalake
aws glue get-databases --region us-east-2
```

**Costo si olvidás limpiar**: ~$17/mes (principalmente VPC Endpoint + QuickSight + CloudWatch Dashboard)

---

## 📚 Referencias

- [AWS Pricing Calculator](https://calculator.aws/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [Glue Pricing](https://aws.amazon.com/glue/pricing/)
- [Athena Pricing](https://aws.amazon.com/athena/pricing/)
- [QuickSight Pricing](https://aws.amazon.com/quicksight/pricing/)
- [VPC Endpoint Pricing](https://aws.amazon.com/privatelink/pricing/)

---

**Última actualización**: Abril 2026
**Región**: us-east-2 (Ohio)
