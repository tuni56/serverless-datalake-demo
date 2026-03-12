# Contributing to Serverless Data Lake Demo

¡Gracias por tu interés en contribuir! Este documento proporciona guías para contribuir al proyecto.

## Código de Conducta

Este proyecto adhiere a un código de conducta. Al participar, se espera que mantengas este código.

## ¿Cómo Contribuir?

### Reportar Bugs

Si encuentras un bug, por favor crea un issue con:

- Descripción clara del problema
- Pasos para reproducir
- Comportamiento esperado vs actual
- Screenshots si aplica
- Versión de Terraform, Python, AWS CLI

### Sugerir Mejoras

Para sugerir mejoras:

1. Verifica que no exista un issue similar
2. Crea un nuevo issue describiendo la mejora
3. Explica por qué sería útil para el proyecto

### Pull Requests

1. Fork el repositorio
2. Crea una rama desde `develop`:
   ```bash
   git checkout develop
   git checkout -b feature/mi-mejora
   ```
3. Realiza tus cambios siguiendo las convenciones del proyecto
4. Commitea usando [Conventional Commits](https://www.conventionalcommits.org/)
5. Push a tu fork
6. Crea un Pull Request a `develop`

### Convenciones de Código

#### Terraform
- Usar nombres descriptivos para recursos
- Agregar descriptions a todas las variables
- Usar outputs para valores importantes
- Seguir [Terraform Best Practices](https://www.terraform-best-practices.com/)

#### Python
- Seguir [PEP 8](https://pep8.org/)
- Usar type hints cuando sea posible
- Documentar funciones con docstrings
- Formatear con `black`

#### SQL
- Keywords en MAYÚSCULAS
- Nombres de tablas/columnas en minúsculas
- Indentar subconsultas
- Comentar queries complejas

### Testing

Antes de enviar un PR:

```bash
# Terraform
cd terraform/environments/dev
terraform init
terraform validate
terraform plan

# Python
cd data-generator
pip install -r requirements.txt
python generate_ecommerce_data.py

# Glue Job (local test)
cd glue-jobs
python transform_raw_to_curated.py --help
```

### Documentación

- Actualizar README.md si cambias funcionalidad
- Actualizar CHANGELOG.md siguiendo [Keep a Changelog](https://keepachangelog.com/)
- Agregar comentarios en código complejo
- Actualizar docs/ si cambias arquitectura

## Proceso de Revisión

1. Un maintainer revisará tu PR
2. Se pueden solicitar cambios
3. Una vez aprobado, se mergeará a `develop`
4. Los cambios llegarán a `main` en el próximo release

## Preguntas

Si tienes preguntas, puedes:
- Abrir un issue con la etiqueta "question"
- Contactar a los maintainers
- Preguntar en el AWS User Group La Paz

¡Gracias por contribuir! 🚀
