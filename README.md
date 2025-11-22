# StockMaster PyME

<p align="center">
  <img src="Logo.png" width="100%" alt="Logo del proyecto">
</p>

StockMaster PyME es una aplicación móvil desarrollada en Flutter para la gestión de inventario en pequeñas y medianas empresas. Este proyecto forma parte de un trabajo académico en Ingeniería de Software y sigue prácticas de arquitectura modular, documentación formal y control de versiones.

## 1. Descripción General

La aplicación permite administrar productos, proveedores, movimientos de inventario y métricas operativas. Su propósito es proporcionar una herramienta confiable para el control de existencias y la toma de decisiones internas.

## 2. Características Principales

### 2.1 Gestión de Usuarios
- Autenticación (Firebase Authentication - planificado)
- Roles: Administrador y Usuario Operativo
- Control de permisos

### 2.2 Gestión de Inventario
- CRUD de productos
- Stock mínimo configurable
- Alertas por desabastecimiento
- Soporte opcional para fecha de caducidad

### 2.3 Movimientos de Inventario
- Entradas, salidas y ajustes
- Auditoría de movimientos
- Historial consultable por fecha

### 2.4 Dashboard
- Indicadores resumen
- Valor estimado del inventario
- Productos críticos
- Movimientos recientes

### 2.5 Reportes
- Exportación de listados
- Reportes filtrados por rango de fechas
- Exportación a PDF (en desarrollo)

## 3. Arquitectura del Proyecto

El proyecto sigue una arquitectura por capas:
- Presentación (Flutter)
- Lógica de negocio modular
- Persistencia planeada en Firebase
- Servicios externos programados para expansión futura

## 4. Estructura del Repositorio

```
inventario/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── lib/
├── test/
├── integration_test/
├── image/
│   └── DOCUMENTACION_PROYECTO/
├── pubspec.yaml
└── README.md
```

## 5. Tecnologías Utilizadas
- Flutter (Dart)
- Firebase (planificado)
- Git y GitHub
- Arquitectura modular

## 6. Requisitos Previos
- Flutter SDK estable
- Dart SDK
- Android Studio o Visual Studio Code
- SDK de Android configurado

## 7. Instalación

```
git clone https://github.com/Wissbegierde/inventario.git
cd inventario
flutter pub get
flutter run
```

## 8. Autores

- Roger Schneider Fuentes Garcés — Product Owner  
- Thomas Alejandro Pérez Rojas — Equipo de desarrollo  
- Juan David Mena Gamboa — Scrum Master  
- Juan Daniel Sandoval — Equipo de desarrollo  

