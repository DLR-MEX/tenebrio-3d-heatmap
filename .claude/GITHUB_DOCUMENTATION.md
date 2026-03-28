# GitHub Documentation Generation Rules

Este archivo define qué documentación pública debe generarse para el repositorio
y qué contenido debe incluir cada archivo.

Claude debe seguir estas reglas al generar o actualizar documentación.

---

# Required Documentation Files

El repositorio debe contener los siguientes archivos de documentación:

README.md  
ARCHITECTURE.md  
SYSTEM_DESCRIPTION.md  
API_REFERENCE.md  
INSTALLATION.md  

Claude debe generar y mantener estos archivos.

---

# README.md

Documento principal del repositorio.

Debe incluir las siguientes secciones:

## Project Overview
Descripción breve del sistema.

## Features
Lista de funcionalidades principales.

## System Architecture
Referencia a ARCHITECTURE.md.

## Installation
Referencia a INSTALLATION.md.

## API
Referencia a API_REFERENCE.md.

## Project Structure
Estructura general del proyecto.

---

# ARCHITECTURE.md

Describe la arquitectura del sistema.

Debe incluir:

## Components

- MQTT Client
- Heatmap Engine
- API Server
- Visualization Frontend

## Architecture Diagram

Sensors
   │
   │ MQTT
   ▼
MQTT Client
   │
   ▼
Heatmap Engine
   │
   ▼
Flask API
   │
   ▼
Frontend (Plotly.js)

## Component Responsibilities

Explicación de cada módulo del backend.

---

# SYSTEM_DESCRIPTION.md

Describe el sistema desde el punto de vista funcional.

Debe incluir:

## System Context

Descripción del cuarto de producción.

## Sensors

Número de sensores y qué miden.

## Monitoring Goal

Objetivo del monitoreo térmico.

## Visualization Purpose

Para qué sirve el mapa de calor.

---

# API_REFERENCE.md

Documentación de la API del sistema.

Debe incluir:

## GET /

Renderiza el dashboard principal.

## GET /api/data

Devuelve datos JSON para la visualización.

Example response:

{
  "sensors": [],
  "volume": [],
  "timestamp": ""
}

---

# INSTALLATION.md

Instrucciones para instalar y ejecutar el sistema.

Debe incluir:

## Requirements

Python 3.x

## Install Dependencies

pip install -r requirements.txt

## Run System

python backend/main.py

---

# Documentation Rules

Claude debe seguir estas reglas:

- La documentación pública debe escribirse en inglés
- Debe reflejar el funcionamiento real del sistema
- No debe inventar funcionalidades inexistentes
- Debe actualizarse cuando cambie la arquitectura

---

# Documentation Sources

Para generar la documentación Claude debe usar:

ARCHITECTURE.md  
SYSTEM_DESCRIPTION.md  
FILES.md  
backend/ source code