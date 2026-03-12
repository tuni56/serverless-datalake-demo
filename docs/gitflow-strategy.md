# Estrategia de Branching - GitFlow

Este proyecto utiliza **GitFlow** como estrategia de branching para simular un entorno de desarrollo profesional.

## Estructura de Ramas

```
main (producción)
  │
  ├── develop (integración)
  │     │
  │     ├── feature/data-generator
  │     ├── feature/terraform-infrastructure
  │     ├── feature/glue-etl-job
  │     ├── feature/athena-queries
  │     │
  │     └── release/v1.0.0
  │
  └── hotfix/critical-bug (si es necesario)
```

## Descripción de Ramas

### Ramas Permanentes

#### `main`
- **Propósito**: Código en producción
- **Protección**: Solo merge desde `release/*` o `hotfix/*`
- **Tags**: Cada merge recibe un tag de versión (v1.0.0, v1.1.0, etc.)
- **Deploy**: Automático a ambiente de producción

#### `develop`
- **Propósito**: Rama de integración para desarrollo
- **Protección**: Solo merge desde `feature/*` o `release/*`
- **Estado**: Siempre debe estar en estado deployable
- **Deploy**: Automático a ambiente de desarrollo

### Ramas Temporales

#### `feature/*`
- **Propósito**: Desarrollo de nuevas funcionalidades
- **Naming**: `feature/nombre-descriptivo`
- **Base**: Se crea desde `develop`
- **Merge**: Se mergea a `develop` via Pull Request
- **Ejemplos**:
  - `feature/data-generator`
  - `feature/terraform-s3-module`
  - `feature/glue-crawler-config`
  - `feature/athena-optimization`

#### `release/*`
- **Propósito**: Preparación de una nueva versión para producción
- **Naming**: `release/vX.Y.Z`
- **Base**: Se crea desde `develop`
- **Merge**: Se mergea a `main` y `develop`
- **Actividades**:
  - Últimos ajustes
  - Actualización de versiones
  - Testing final
  - Documentación

#### `hotfix/*`
- **Propósito**: Corrección urgente en producción
- **Naming**: `hotfix/descripcion-bug`
- **Base**: Se crea desde `main`
- **Merge**: Se mergea a `main` y `develop`
- **Ejemplos**:
  - `hotfix/glue-job-timeout`
  - `hotfix/s3-permissions`

## Flujo de Trabajo

### 1. Desarrollar Nueva Funcionalidad

```bash
# Actualizar develop
git checkout develop
git pull origin develop

# Crear feature branch
git checkout -b feature/nueva-funcionalidad

# Desarrollar y commitear
git add .
git commit -m "feat: implementar nueva funcionalidad"

# Push a remoto
git push origin feature/nueva-funcionalidad

# Crear Pull Request a develop
# (En GitHub/GitLab/Bitbucket)
```

### 2. Preparar Release

```bash
# Crear release branch desde develop
git checkout develop
git pull origin develop
git checkout -b release/v1.0.0

# Ajustes finales
# - Actualizar versiones
# - Actualizar CHANGELOG.md
# - Testing final

git commit -m "chore: prepare release v1.0.0"
git push origin release/v1.0.0

# Merge a main
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags

# Merge a develop
git checkout develop
git merge --no-ff release/v1.0.0
git push origin develop

# Eliminar release branch
git branch -d release/v1.0.0
git push origin --delete release/v1.0.0
```

### 3. Hotfix en Producción

```bash
# Crear hotfix branch desde main
git checkout main
git pull origin main
git checkout -b hotfix/critical-bug

# Corregir bug
git add .
git commit -m "fix: corregir bug crítico"

# Merge a main
git checkout main
git merge --no-ff hotfix/critical-bug
git tag -a v1.0.1 -m "Hotfix version 1.0.1"
git push origin main --tags

# Merge a develop
git checkout develop
git merge --no-ff hotfix/critical-bug
git push origin develop

# Eliminar hotfix branch
git branch -d hotfix/critical-bug
git push origin --delete hotfix/critical-bug
```

## Convenciones de Commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Formato, punto y coma faltante, etc.
- `refactor`: Refactorización de código
- `test`: Agregar tests
- `chore`: Mantenimiento, dependencias, etc.
- `perf`: Mejoras de performance
- `ci`: Cambios en CI/CD

### Ejemplos

```bash
feat(glue): agregar particionamiento por fecha en ETL job

Implementa particionamiento automático de orders por año/mes
para optimizar queries de Athena.

Closes #123
```

```bash
fix(terraform): corregir permisos IAM para Glue Crawler

El crawler no podía leer objetos de S3 debido a permisos
insuficientes en la policy.

Fixes #456
```

## Pull Request Guidelines

### Template

```markdown
## Descripción
Breve descripción de los cambios

## Tipo de cambio
- [ ] Bug fix
- [ ] Nueva funcionalidad
- [ ] Breaking change
- [ ] Documentación

## Checklist
- [ ] Código sigue las convenciones del proyecto
- [ ] Tests agregados/actualizados
- [ ] Documentación actualizada
- [ ] Terraform plan ejecutado sin errores
- [ ] No hay secretos hardcodeados

## Testing
Describe cómo se testeó

## Screenshots (si aplica)
```

### Revisión de Código

Requisitos para aprobar PR:
- ✅ Al menos 1 aprobación
- ✅ CI/CD pipeline pasa
- ✅ No conflictos con rama base
- ✅ Documentación actualizada

## Protección de Ramas

### `main`
- ✅ Require pull request reviews (1 aprobación)
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Include administrators
- ✅ Restrict who can push

### `develop`
- ✅ Require pull request reviews (1 aprobación)
- ✅ Require status checks to pass
- ✅ Require branches to be up to date

## Versionamiento Semántico

Seguimos [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH

1.0.0 → 1.0.1 (patch: bug fix)
1.0.1 → 1.1.0 (minor: nueva funcionalidad)
1.1.0 → 2.0.0 (major: breaking change)
```

## CI/CD Pipeline (Conceptual)

```yaml
# .github/workflows/ci.yml (ejemplo)

on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop, main]

jobs:
  terraform-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Terraform Init
        run: terraform init
      - name: Terraform Validate
        run: terraform validate
      - name: Terraform Plan
        run: terraform plan

  python-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
      - name: Install dependencies
        run: pip install flake8 black
      - name: Lint with flake8
        run: flake8 .
      - name: Format check with black
        run: black --check .
```

## Comandos Útiles

```bash
# Ver todas las ramas
git branch -a

# Ver historial gráfico
git log --oneline --graph --all

# Limpiar ramas locales eliminadas en remoto
git fetch --prune

# Ver diferencias entre ramas
git diff develop..main

# Listar tags
git tag -l

# Checkout a un tag específico
git checkout v1.0.0
```

## Referencias

- [GitFlow Original](https://nvie.com/posts/a-successful-git-branching-model/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
