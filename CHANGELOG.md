# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Planeado
- Integración con AWS Lake Formation para governance
- Glue Triggers para automatización de ETL
- QuickSight dashboards para visualización
- Data Quality rules con AWS Glue Data Quality
- Streaming ingestion con Kinesis Firehose

## [1.0.0] - 2026-03-12

### Agregado
- Infraestructura completa con Terraform
  - Módulos para IAM, S3, Glue, Athena
  - Ambientes dev y prod
- Generador de datos sintéticos de e-commerce
  - 10,000 customers
  - 500 products
  - 50,000 orders
- Glue ETL Job para transformación CSV a Parquet
  - Particionamiento por año/mes
  - Compresión Snappy
- Glue Crawlers para descubrimiento de schema
  - Raw layer (CSV)
  - Curated layer (Parquet)
- 10 queries SQL de ejemplo para Athena
  - Análisis de ventas
  - Top productos y clientes
  - Análisis de cohortes
- Documentación completa
  - Guía de deployment
  - Análisis de costos
  - Arquitectura detallada
  - Estrategia GitFlow
- Scripts de automatización
  - setup.sh para deployment
  - cleanup.sh para eliminación de recursos
- Seguridad implementada
  - Encryption at rest (SSE-S3)
  - Encryption in transit (TLS)
  - IAM roles con least privilege
  - Bucket policies restrictivas
  - Versionamiento habilitado

### Seguridad
- Todos los buckets S3 con encryption at rest
- Políticas de bucket que niegan tráfico HTTP
- IAM roles con principio de least privilege
- Block public access habilitado en todos los buckets

## [0.2.0] - 2026-03-10

### Agregado
- Módulo Terraform para Athena
- Queries SQL de ejemplo
- Documentación de arquitectura

### Cambiado
- Glue Job migrado de Spark a Python Shell para reducir costos
- Optimización de particionamiento en orders

## [0.1.0] - 2026-03-08

### Agregado
- Estructura inicial del proyecto
- Módulos Terraform para S3 y Glue
- Generador básico de datos
- README inicial

---

## Tipos de Cambios

- `Agregado` para nuevas funcionalidades
- `Cambiado` para cambios en funcionalidades existentes
- `Deprecado` para funcionalidades que serán removidas
- `Removido` para funcionalidades removidas
- `Corregido` para corrección de bugs
- `Seguridad` para vulnerabilidades

[Unreleased]: https://github.com/usuario/serverless-datalake-demo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/usuario/serverless-datalake-demo/compare/v0.2.0...v1.0.0
[0.2.0]: https://github.com/usuario/serverless-datalake-demo/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/usuario/serverless-datalake-demo/releases/tag/v0.1.0
