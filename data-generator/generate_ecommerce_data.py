import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

# Configuración
OUTPUT_DIR = 'output'
NUM_CUSTOMERS = 10000
NUM_PRODUCTS = 500
NUM_ORDERS = 50000

# Crear directorio de salida
os.makedirs(OUTPUT_DIR, exist_ok=True)

def generate_customers():
    """Genera dataset de clientes"""
    print("Generando customers...")
    
    countries = ['Argentina', 'Bolivia', 'Brasil', 'Chile', 'Colombia', 'Ecuador', 
                 'Paraguay', 'Peru', 'Uruguay', 'Venezuela']
    
    customers = []
    for i in range(1, NUM_CUSTOMERS + 1):
        customer = {
            'customer_id': i,
            'name': f'Customer_{i}',
            'email': f'customer{i}@example.com',
            'country': random.choice(countries),
            'registration_date': (datetime.now() - timedelta(days=random.randint(1, 730))).strftime('%Y-%m-%d')
        }
        customers.append(customer)
    
    df = pd.DataFrame(customers)
    df.to_csv(f'{OUTPUT_DIR}/customers.csv', index=False)
    print(f"✓ Generados {len(df)} customers")
    return df

def generate_products():
    """Genera dataset de productos"""
    print("Generando products...")
    
    categories = ['Electronics', 'Clothing', 'Home & Garden', 'Sports', 'Books', 
                  'Toys', 'Food & Beverage', 'Beauty', 'Automotive', 'Health']
    
    products = []
    for i in range(1, NUM_PRODUCTS + 1):
        product = {
            'product_id': i,
            'name': f'Product_{i}',
            'category': random.choice(categories),
            'price': round(random.uniform(10, 1000), 2),
            'stock': random.randint(0, 500)
        }
        products.append(product)
    
    df = pd.DataFrame(products)
    df.to_csv(f'{OUTPUT_DIR}/products.csv', index=False)
    print(f"✓ Generados {len(df)} products")
    return df

def generate_orders(customers_df, products_df):
    """Genera dataset de órdenes"""
    print("Generando orders...")
    
    statuses = ['completed', 'pending', 'cancelled', 'refunded']
    status_weights = [0.7, 0.15, 0.1, 0.05]
    
    orders = []
    for i in range(1, NUM_ORDERS + 1):
        customer_id = random.choice(customers_df['customer_id'].values)
        product_id = random.choice(products_df['product_id'].values)
        product_price = products_df[products_df['product_id'] == product_id]['price'].values[0]
        quantity = random.randint(1, 5)
        
        order = {
            'order_id': i,
            'customer_id': customer_id,
            'product_id': product_id,
            'order_date': (order_dt := datetime.now() - timedelta(days=random.randint(1, 365))).strftime('%Y-%m-%d'),
            'year': order_dt.year,
            'month': order_dt.month,
            'quantity': quantity,
            'total_amount': round(product_price * quantity, 2),
            'status': random.choices(statuses, weights=status_weights)[0]
        }
        orders.append(order)
    
    df = pd.DataFrame(orders)
    df.to_csv(f'{OUTPUT_DIR}/orders.csv', index=False)
    print(f"✓ Generados {len(df)} orders")
    return df

def print_statistics(customers_df, products_df, orders_df):
    """Imprime estadísticas de los datasets generados"""
    print("\n" + "="*60)
    print("ESTADÍSTICAS DE DATOS GENERADOS")
    print("="*60)
    
    print(f"\n📊 Customers: {len(customers_df):,}")
    print(f"   - Países únicos: {customers_df['country'].nunique()}")
    
    print(f"\n📦 Products: {len(products_df):,}")
    print(f"   - Categorías: {products_df['category'].nunique()}")
    print(f"   - Precio promedio: ${products_df['price'].mean():.2f}")
    
    print(f"\n🛒 Orders: {len(orders_df):,}")
    print(f"   - Revenue total: ${orders_df['total_amount'].sum():,.2f}")
    print(f"   - Ticket promedio: ${orders_df['total_amount'].mean():.2f}")
    print(f"   - Status distribution:")
    for status, count in orders_df['status'].value_counts().items():
        print(f"     • {status}: {count:,} ({count/len(orders_df)*100:.1f}%)")
    
    # Tamaño de archivos
    customers_size = os.path.getsize(f'{OUTPUT_DIR}/customers.csv') / (1024 * 1024)
    products_size = os.path.getsize(f'{OUTPUT_DIR}/products.csv') / (1024 * 1024)
    orders_size = os.path.getsize(f'{OUTPUT_DIR}/orders.csv') / (1024 * 1024)
    total_size = customers_size + products_size + orders_size
    
    print(f"\n💾 Tamaño de archivos:")
    print(f"   - customers.csv: {customers_size:.2f} MB")
    print(f"   - products.csv: {products_size:.2f} MB")
    print(f"   - orders.csv: {orders_size:.2f} MB")
    print(f"   - TOTAL: {total_size:.2f} MB")
    print("="*60 + "\n")

if __name__ == '__main__':
    print("\n🚀 Generador de Datos E-commerce\n")
    
    customers_df = generate_customers()
    products_df = generate_products()
    orders_df = generate_orders(customers_df, products_df)
    
    print_statistics(customers_df, products_df, orders_df)
    
    print(f"✅ Datos generados exitosamente en: {OUTPUT_DIR}/")
    print("\nPróximos pasos:")
    print("1. Subir archivos a S3: aws s3 cp output/ s3://YOUR-RAW-BUCKET/ --recursive")
    print("2. Ejecutar Glue Crawler")
    print("3. Ejecutar Glue ETL Job")
    print("4. Consultar con Athena\n")
