# Generador de Datos E-commerce

## Instalación con uv (recomendado)

```bash
# Instalar uv si no lo tienes
curl -LsSf https://astral.sh/uv/install.sh | sh

# Crear entorno virtual y instalar dependencias
uv venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
uv pip install -r requirements.txt
```

## Instalación tradicional

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Uso

```bash
python generate_ecommerce_data.py
```

Genera:
- `output/customers.csv` (10,000 registros)
- `output/products.csv` (500 registros)
- `output/orders.csv` (50,000 registros)

## Ventajas de uv

- ⚡ 10-100x más rápido que pip
- 🪶 Más liviano (binario único)
- 🔒 Lock files automáticos
- 🎯 Compatible con pip
