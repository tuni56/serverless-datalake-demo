import sys
import boto3
import pandas as pd
from awsglue.utils import getResolvedOptions
from datetime import datetime

# Obtener argumentos
args = getResolvedOptions(sys.argv, ['RAW_BUCKET', 'CURATED_BUCKET', 'DATABASE_NAME'])

raw_bucket = args['RAW_BUCKET']
curated_bucket = args['CURATED_BUCKET']
database_name = args['DATABASE_NAME']

s3_client = boto3.client('s3')

def transform_orders():
    """Transforma orders de CSV a Parquet con particionamiento"""
    print("Transformando orders...")
    
    # Leer CSV desde S3
    orders_df = pd.read_csv(f's3://{raw_bucket}/orders/orders.csv')
    
    # Convertir order_date a datetime
    orders_df['order_date'] = pd.to_datetime(orders_df['order_date'])
    
    # Agregar columnas de partición
    orders_df['year'] = orders_df['order_date'].dt.year
    orders_df['month'] = orders_df['order_date'].dt.month
    
    # Escribir a Parquet particionado
    orders_df.to_parquet(
        f's3://{curated_bucket}/orders/',
        engine='pyarrow',
        compression='snappy',
        partition_cols=['year', 'month'],
        index=False
    )
    
    print(f"Orders transformados: {len(orders_df)} registros")

def transform_customers():
    """Transforma customers de CSV a Parquet"""
    print("Transformando customers...")
    
    customers_df = pd.read_csv(f's3://{raw_bucket}/customers/customers.csv')
    customers_df['registration_date'] = pd.to_datetime(customers_df['registration_date'])
    
    # Escribir a Parquet
    customers_df.to_parquet(
        f's3://{curated_bucket}/customers/customers.parquet',
        engine='pyarrow',
        compression='snappy',
        index=False
    )
    
    print(f"Customers transformados: {len(customers_df)} registros")

def transform_products():
    """Transforma products de CSV a Parquet"""
    print("Transformando products...")
    
    products_df = pd.read_csv(f's3://{raw_bucket}/products/products.csv')
    
    # Escribir a Parquet
    products_df.to_parquet(
        f's3://{curated_bucket}/products/products.parquet',
        engine='pyarrow',
        compression='snappy',
        index=False
    )
    
    print(f"Products transformados: {len(products_df)} registros")

if __name__ == '__main__':
    start_time = datetime.now()
    print(f"Iniciando transformación: {start_time}")
    
    transform_orders()
    transform_customers()
    transform_products()
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    print(f"Transformación completada en {duration} segundos")
