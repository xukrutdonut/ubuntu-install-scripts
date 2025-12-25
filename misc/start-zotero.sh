#!/bin/bash

# Script para iniciar Zotero Web Server con rutas corregidas
echo "🚀 Iniciando Zotero Web Server..."

# Crear directorio de logs si no existe
mkdir -p logs

# Verificar que los archivos existen
echo "📋 Verificando archivos..."
if [ ! -f "/home/arkantu/Zotero/zotero.sqlite" ]; then
    echo "❌ ERROR: No se encontró zotero.sqlite en /home/arkantu/Zotero/"
    exit 1
fi

if [ ! -d "/home/arkantu/Documentos/Zotero Biblioteca" ]; then
    echo "❌ ERROR: No se encontró la biblioteca en /home/arkantu/Documentos/Zotero Biblioteca/"
    exit 1
fi

if [ ! -d "/home/arkantu/Zotero/storage" ]; then
    echo "❌ ERROR: No se encontró el directorio storage en /home/arkantu/Zotero/storage/"
    exit 1
fi

echo "✅ Archivos verificados correctamente"

# Contar PDFs en biblioteca
PDFS_BIBLIOTECA=$(find "/home/arkantu/Documentos/Zotero Biblioteca" -name "*.pdf" -type f 2>/dev/null | wc -l)
PDFS_STORAGE=$(find "/home/arkantu/Zotero/storage" -name "*.pdf" -type f 2>/dev/null | wc -l)

echo "📚 PDFs encontrados:"
echo "   - Biblioteca: $PDFS_BIBLIOTECA PDFs"
echo "   - Storage: $PDFS_STORAGE PDFs"
echo "   - Total: $((PDFS_BIBLIOTECA + PDFS_STORAGE)) PDFs"

# Iniciar contenedor
echo "🐳 Iniciando Docker container..."
docker compose up -d

if [ $? -eq 0 ]; then
    echo "✅ Contenedor iniciado exitosamente"
    echo "🌐 Servidor disponible en: http://localhost:3002"
    echo "📊 Estadísticas en: http://localhost:3002/api/stats"
    echo "📋 Ver logs: docker logs -f zotero-web-server"
else
    echo "❌ Error al iniciar el contenedor"
    exit 1
fi