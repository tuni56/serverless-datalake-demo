# QuickSight Integration

## Overview

Integración con Amazon QuickSight para visualización de datos del Data Lake.

## Dashboards Propuestos

### 1. Executive Dashboard
- Revenue total y tendencia
- Top 10 productos
- Distribución geográfica de ventas
- KPIs principales

### 2. Sales Analytics
- Ventas por categoría
- Análisis de cohortes
- Tasa de conversión
- Ticket promedio

### 3. Customer Analytics
- Segmentación de clientes
- Lifetime value
- Churn analysis
- Comportamiento de compra

## Setup

```bash
# 1. Crear QuickSight account
aws quicksight create-account-subscription \
  --edition ENTERPRISE \
  --authentication-method IAM_AND_QUICKSIGHT

# 2. Dar permisos a Athena
aws quicksight create-data-source \
  --aws-account-id ACCOUNT_ID \
  --data-source-id athena-ecommerce \
  --name "E-commerce Data Lake" \
  --type ATHENA \
  --data-source-parameters AthenaParameters={WorkGroup=ecommerce-datalake-workgroup-dev}
```

## Datasets

- orders_curated
- customers
- products
- sales_summary (view)

## Próximos Pasos

- Crear datasets en QuickSight
- Diseñar dashboards
- Configurar refresh schedule
- Compartir con stakeholders
