#!/bin/bash

# ============================================
# COMANDOS ÚTILES PARA LA DEMO
# ============================================

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

REGION="us-east-2"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Comandos Útiles - Data Lake Demo${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Función para obtener outputs de Terraform
get_terraform_outputs() {
    cd terraform/environments/dev
    export RAW_BUCKET=$(terraform output -raw raw_bucket_name 2>/dev/null)
    export CURATED_BUCKET=$(terraform output -raw curated_bucket_name 2>/dev/null)
    export SCRIPTS_BUCKET=$(terraform output -raw scripts_bucket_name 2>/dev/null)
    export ATHENA_BUCKET=$(terraform output -raw athena_results_bucket_name 2>/dev/null)
    export DATABASE_NAME=$(terraform output -raw glue_database_name 2>/dev/null)
    export CRAWLER_NAME=$(terraform output -raw glue_crawler_name 2>/dev/null)
    export JOB_NAME=$(terraform output -raw glue_job_name 2>/dev/null)
    cd ../../..
}

# Menú principal
show_menu() {
    echo -e "${GREEN}Selecciona una opción:${NC}\n"
    echo "1)  Ver buckets S3"
    echo "2)  Listar archivos en raw bucket"
    echo "3)  Listar archivos en curated bucket"
    echo "4)  Ver tamaño de datos (raw vs curated)"
    echo "5)  Ejecutar Glue Crawler (raw)"
    echo "6)  Ver estado de Glue Crawler"
    echo "7)  Ejecutar Glue ETL Job"
    echo "8)  Ver estado de Glue Job"
    echo "9)  Ver logs de Glue Job"
    echo "10) Listar tablas en Glue Catalog"
    echo "11) Ver schema de tabla orders"
    echo "12) Ver particiones de orders"
    echo "13) Ejecutar query de prueba en Athena"
    echo "14) Ver queries recientes en Athena"
    echo "15) Limpiar resultados de Athena"
    echo "16) Ver costos estimados"
    echo "17) Mostrar variables de entorno"
    echo "0)  Salir"
    echo ""
}

# Funciones
view_buckets() {
    echo -e "${YELLOW}Buckets S3:${NC}"
    aws s3 ls | grep ecommerce-datalake
}

list_raw_files() {
    echo -e "${YELLOW}Archivos en raw bucket:${NC}"
    aws s3 ls s3://$RAW_BUCKET/ --recursive --human-readable --summarize
}

list_curated_files() {
    echo -e "${YELLOW}Archivos en curated bucket:${NC}"
    aws s3 ls s3://$CURATED_BUCKET/ --recursive --human-readable --summarize
}

compare_sizes() {
    echo -e "${YELLOW}Comparación de tamaños:${NC}\n"
    echo "Raw (CSV):"
    aws s3 ls s3://$RAW_BUCKET/ --recursive --summarize | grep "Total Size"
    echo ""
    echo "Curated (Parquet):"
    aws s3 ls s3://$CURATED_BUCKET/ --recursive --summarize | grep "Total Size"
}

start_crawler() {
    echo -e "${YELLOW}Ejecutando Glue Crawler...${NC}"
    aws glue start-crawler --name $CRAWLER_NAME --region $REGION
    echo "Crawler iniciado. Usa opción 6 para ver el estado."
}

check_crawler_status() {
    echo -e "${YELLOW}Estado del Crawler:${NC}"
    aws glue get-crawler --name $CRAWLER_NAME --region $REGION --query 'Crawler.{State:State,LastCrawl:LastCrawl.Status}'
}

start_job() {
    echo -e "${YELLOW}Ejecutando Glue ETL Job...${NC}"
    JOB_RUN_ID=$(aws glue start-job-run --job-name $JOB_NAME --region $REGION --query 'JobRunId' --output text)
    echo "Job iniciado con ID: $JOB_RUN_ID"
    echo "Usa opción 8 para ver el estado."
}

check_job_status() {
    echo -e "${YELLOW}Estado del último Job:${NC}"
    aws glue get-job-runs --job-name $JOB_NAME --region $REGION --max-items 1 --query 'JobRuns[0].{State:JobRunState,StartedOn:StartedOn,ExecutionTime:ExecutionTime}'
}

view_job_logs() {
    echo -e "${YELLOW}Logs del Glue Job (últimas 50 líneas):${NC}"
    aws logs tail /aws-glue/jobs/output --since 1h --region $REGION | tail -50
}

list_tables() {
    echo -e "${YELLOW}Tablas en Glue Catalog:${NC}"
    aws glue get-tables --database-name $DATABASE_NAME --region $REGION --query 'TableList[*].[Name,StorageDescriptor.Location]' --output table
}

view_orders_schema() {
    echo -e "${YELLOW}Schema de tabla orders:${NC}"
    aws glue get-table --database-name $DATABASE_NAME --name orders --region $REGION --query 'Table.StorageDescriptor.Columns' --output table
}

view_partitions() {
    echo -e "${YELLOW}Particiones de orders:${NC}"
    aws glue get-partitions --database-name $DATABASE_NAME --table-name orders --region $REGION --query 'Partitions[*].Values' --output table
}

run_test_query() {
    echo -e "${YELLOW}Ejecutando query de prueba...${NC}"
    QUERY_ID=$(aws athena start-query-execution \
        --query-string "SELECT COUNT(*) as total_orders FROM orders" \
        --query-execution-context Database=$DATABASE_NAME \
        --result-configuration OutputLocation=s3://$ATHENA_BUCKET/ \
        --work-group ecommerce-datalake-workgroup-dev \
        --region $REGION \
        --query 'QueryExecutionId' --output text)
    
    echo "Query ejecutada con ID: $QUERY_ID"
    sleep 3
    
    echo -e "\n${YELLOW}Resultado:${NC}"
    aws athena get-query-results --query-execution-id $QUERY_ID --region $REGION --query 'ResultSet.Rows' --output table
}

view_recent_queries() {
    echo -e "${YELLOW}Queries recientes en Athena:${NC}"
    aws athena list-query-executions --work-group ecommerce-datalake-workgroup-dev --region $REGION --max-items 10 --query 'QueryExecutionIds' --output table
}

cleanup_athena_results() {
    echo -e "${YELLOW}Limpiando resultados de Athena...${NC}"
    aws s3 rm s3://$ATHENA_BUCKET/ --recursive
    echo "Resultados eliminados."
}

show_costs() {
    echo -e "${YELLOW}Costos estimados:${NC}\n"
    echo "Demo completa: < \$5 USD"
    echo ""
    echo "Desglose:"
    echo "  - S3 Storage: \$0 (free tier)"
    echo "  - S3 Requests: \$0 (free tier)"
    echo "  - Glue Crawler: \$0 (free tier)"
    echo "  - Glue ETL Job: \$0 (free tier)"
    echo "  - Athena Queries: ~\$0.005"
    echo ""
    echo "Ver docs/cost-analysis.md para más detalles."
}

show_env_vars() {
    echo -e "${YELLOW}Variables de entorno:${NC}\n"
    echo "RAW_BUCKET=$RAW_BUCKET"
    echo "CURATED_BUCKET=$CURATED_BUCKET"
    echo "SCRIPTS_BUCKET=$SCRIPTS_BUCKET"
    echo "ATHENA_BUCKET=$ATHENA_BUCKET"
    echo "DATABASE_NAME=$DATABASE_NAME"
    echo "CRAWLER_NAME=$CRAWLER_NAME"
    echo "JOB_NAME=$JOB_NAME"
    echo "REGION=$REGION"
}

# Main loop
get_terraform_outputs

while true; do
    show_menu
    read -p "Opción: " option
    echo ""
    
    case $option in
        1) view_buckets ;;
        2) list_raw_files ;;
        3) list_curated_files ;;
        4) compare_sizes ;;
        5) start_crawler ;;
        6) check_crawler_status ;;
        7) start_job ;;
        8) check_job_status ;;
        9) view_job_logs ;;
        10) list_tables ;;
        11) view_orders_schema ;;
        12) view_partitions ;;
        13) run_test_query ;;
        14) view_recent_queries ;;
        15) cleanup_athena_results ;;
        16) show_costs ;;
        17) show_env_vars ;;
        0) echo "¡Hasta luego!"; exit 0 ;;
        *) echo -e "${YELLOW}Opción inválida${NC}" ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
    clear
done
