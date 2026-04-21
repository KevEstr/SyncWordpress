#!/bin/bash
# Script para configurar el cron job en Linux/Mac

# Obtener la ruta absoluta del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PYTHON_PATH=$(which python3)

# Crear entrada de cron (ejecutar diariamente a las 7 PM)
CRON_JOB="0 19 * * * cd $SCRIPT_DIR && $PYTHON_PATH sync_inventory.py >> $SCRIPT_DIR/cron.log 2>&1"

# Agregar al crontab
(crontab -l 2>/dev/null | grep -v "sync_inventory.py"; echo "$CRON_JOB") | crontab -

echo "✓ Cron job configurado exitosamente"
echo "El script se ejecutará diariamente a las 7:00 PM"
echo ""
echo "Para verificar: crontab -l"
echo "Para ver logs: tail -f $SCRIPT_DIR/cron.log"
