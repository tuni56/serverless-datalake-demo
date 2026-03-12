# Data Quality Checks

## Overview

Este módulo implementa validaciones de calidad de datos en el pipeline ETL.

## Checks Implementados

### 1. Completeness
- Verificar que campos obligatorios no sean nulos
- Validar que no haya registros duplicados

### 2. Accuracy
- Validar rangos de valores (ej: price > 0)
- Verificar formatos de fecha
- Validar foreign keys

### 3. Consistency
- Verificar que order_date <= current_date
- Validar que total_amount = price * quantity

## Implementación

```python
def validate_orders(df):
    """Valida calidad de datos en orders"""
    
    # Completeness
    assert df['order_id'].notna().all(), "order_id tiene valores nulos"
    assert df['order_id'].is_unique, "order_id tiene duplicados"
    
    # Accuracy
    assert (df['total_amount'] > 0).all(), "total_amount debe ser > 0"
    assert (df['quantity'] > 0).all(), "quantity debe ser > 0"
    
    # Consistency
    assert (df['order_date'] <= pd.Timestamp.now()).all(), "order_date en el futuro"
    
    return True
```

## Métricas

- Total de registros procesados
- Registros válidos vs inválidos
- Tipos de errores encontrados
- Tiempo de validación

## Próximos Pasos

- Integrar con AWS Glue Data Quality
- Enviar alertas a SNS en caso de fallas
- Dashboard de métricas en CloudWatch
