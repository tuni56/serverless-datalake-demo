#!/bin/bash

# Script para crear y pushear el repositorio a GitHub

set -e

echo "🚀 Creando repositorio en GitHub..."

cd /home/rocio/serverless-datalake-demo

# Verificar que estamos en la rama develop
git checkout develop

# Crear repo en GitHub (público)
gh repo create serverless-datalake-demo \
  --public \
  --source=. \
  --description="Data Lake Serverless en AWS con S3, Glue y Athena - Demo User Group La Paz" \
  --push

echo ""
echo "✅ Repositorio creado exitosamente!"
echo ""
echo "📍 URL: https://github.com/$(gh api user -q .login)/serverless-datalake-demo"
echo ""
echo "Próximos pasos:"
echo "1. Pushear todas las ramas:"
echo "   git push origin main"
echo "   git push origin develop"
echo "   git push origin feature/add-data-quality-checks"
echo "   git push origin feature/add-quicksight-integration"
echo ""
echo "2. Pushear tags:"
echo "   git push origin --tags"
echo ""
echo "3. Configurar rama default en GitHub:"
echo "   gh repo edit --default-branch main"
