# Sincronizador de Inventario WordPress - API

Script profesional en Python para sincronizar automáticamente el inventario de WooCommerce con una API externa. Actualiza precios y stock diariamente.

## Características

- ✅ Sincronización automática de stock y precios
- ✅ Trabaja solo con productos existentes (no crea ni elimina)
- ✅ La API es la fuente de verdad
- ✅ Logging detallado de todas las operaciones
- ✅ Manejo robusto de errores
- ✅ Paginación automática para grandes inventarios
- ✅ Ejecución programada diaria (cron/task scheduler)

## Requisitos

- Python 3.7 o superior
- Acceso a WordPress con WooCommerce
- Credenciales de API de WooCommerce

## Instalación

### 1. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 2. Configurar credenciales de WordPress

Edita el archivo `sync_inventory.py` y actualiza estas líneas:

```python
WP_URL = "https://tu-tienda.com"  # Tu URL de WordPress
WP_API_KEY = "ck_tu_consumer_key"  # Tu consumer key
WP_API_SECRET = "cs_tu_consumer_secret"  # Tu consumer secret
```

#### ¿Cómo obtener las credenciales de WooCommerce?

1. Ir a WordPress Admin
2. WooCommerce → Configuración → Avanzado → REST API
3. Clic en "Añadir clave"
4. Descripción: "Sincronización Inventario"
5. Usuario: Seleccionar un administrador
6. Permisos: "Lectura/Escritura"
7. Copiar el Consumer Key y Consumer Secret

### 3. Configurar ejecución automática

#### En Linux/Mac:

```bash
chmod +x setup_cron.sh
./setup_cron.sh
```

#### En Windows:

Ejecutar como administrador:
```
setup_task_windows.bat
```

## Uso Manual

Para ejecutar el script manualmente:

```bash
python sync_inventory.py
```

## Logs

El script genera dos archivos de log:

- `sync_inventory.log` - Log detallado de todas las operaciones
- `cron.log` - Log de ejecuciones automáticas (solo cron)

Ver logs en tiempo real:
```bash
tail -f sync_inventory.log
```

## Funcionamiento

1. **Obtiene inventario de la API** - Descarga todos los productos activos
2. **Obtiene productos de WordPress** - Lista todos los productos publicados
3. **Compara por SKU** - Busca cada producto de WordPress en la API usando el SKU
4. **Actualiza si hay diferencias**:
   - Si el stock es diferente → actualiza con el de la API
   - Si el precio es diferente → actualiza con el de la API
5. **Genera reporte** - Muestra estadísticas de la sincronización

## Importante

- El script **NO crea nuevos productos**
- El script **NO elimina productos**
- Solo actualiza productos existentes que tengan SKU
- La API siempre tiene prioridad sobre WordPress
- Los productos sin SKU son ignorados
- Los productos no encontrados en la API son ignorados

## Solución de Problemas

### Error de conexión a WordPress

Verificar:
- URL correcta (con https://)
- Credenciales de API válidas
- WooCommerce instalado y activo

### Productos no se actualizan

Verificar:
- Los productos tienen SKU configurado
- El SKU coincide con el campo "codigo" de la API
- Los productos están publicados (no en borrador)

### Error de permisos en cron

```bash
chmod +x sync_inventory.py
chmod +x setup_cron.sh
```

## Personalización

### Cambiar hora de ejecución

Editar en `setup_cron.sh` (Linux/Mac):
```bash
# Cambiar "0 19" por la hora deseada (formato 24h)
0 19 * * *  # 7:00 PM
0 9 * * *   # 9:00 AM
30 14 * * * # 2:30 PM
```

Editar en `setup_task_windows.bat` (Windows):
```batch
/st 19:00  REM Cambiar por la hora deseada
```

### Cambiar frecuencia de actualización

El script está configurado para ejecutarse diariamente. Para cambiar:

**Cada 6 horas:**
```bash
0 */6 * * * cd /ruta/script && python3 sync_inventory.py
```

**Dos veces al día (9 AM y 7 PM):**
```bash
0 9,19 * * * cd /ruta/script && python3 sync_inventory.py
```

## Soporte

Para problemas o preguntas, revisar los logs en `sync_inventory.log`
