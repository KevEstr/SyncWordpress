#!/usr/bin/env python3
"""
Script de sincronización de inventario WordPress con API externa.
Actualiza precios y stock de productos existentes en WooCommerce.
"""

import requests
import logging
from datetime import datetime
from typing import Dict, List, Optional
import time

# Configuración
API_INVENTARIO_URL = "https://pub-9bee73921e1747228cd3ef3cfe689273.r2.dev/inventario.json"

# Configuración WordPress/WooCommerce
WP_URL = "https://nicolpruebas-grupo30.online"  # Tu URL de WordPress
WP_API_KEY = "ck_2704c52a6f5ec53dbd2b7327f9dd7e24c84b93ba"  # Cambiar por tu consumer key
WP_API_SECRET = "cs_baf22afd3062d9503fb243b32c30ce92d9755bc0"  # Cambiar por tu consumer secret

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('sync_inventory.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class InventorySync:
    """Clase para sincronizar inventario entre API y WordPress."""
    
    def __init__(self):
        self.api_url = API_INVENTARIO_URL
        self.wp_url = f"{WP_URL}/wp-json/wc/v3"
        self.auth = (WP_API_KEY, WP_API_SECRET)
        self.stats = {
            'total_wp': 0,
            'actualizados': 0,
            'sin_cambios': 0,
            'errores': 0,
            'no_encontrados': 0
        }
    
    def obtener_inventario_api(self) -> Dict[str, Dict]:
        """Obtiene el inventario completo de la API externa."""
        try:
            logger.info("Obteniendo inventario de la API...")
            response = requests.get(self.api_url, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            productos = data.get('data', [])
            
            # Crear diccionario indexado por SKU (código)
            inventario = {}
            for producto in productos:
                if producto.get('activo', False):
                    sku = producto.get('codigo', '').strip()
                    if sku:
                        inventario[sku] = {
                            'stock': int(producto.get('disponible', 0)),
                            'precio': float(producto.get('precio_venta_1', 0)),
                            'descripcion': producto.get('descripcion', '')
                        }
            
            logger.info(f"Inventario API cargado: {len(inventario)} productos activos")
            return inventario
            
        except Exception as e:
            logger.error(f"Error al obtener inventario de API: {e}")
            raise
    
    def obtener_productos_wordpress(self, page: int = 1) -> List[Dict]:
        """Obtiene productos de WordPress/WooCommerce con paginación."""
        try:
            params = {
                'per_page': 100,
                'page': page,
                'status': 'publish'
            }
            
            response = requests.get(
                f"{self.wp_url}/products",
                auth=self.auth,
                params=params,
                timeout=30
            )
            response.raise_for_status()
            
            return response.json()
            
        except Exception as e:
            logger.error(f"Error al obtener productos de WordPress (página {page}): {e}")
            return []
    
    def obtener_todos_productos_wordpress(self) -> List[Dict]:
        """Obtiene todos los productos de WordPress usando paginación."""
        todos_productos = []
        page = 1
        
        while True:
            productos = self.obtener_productos_wordpress(page)
            if not productos:
                break
            
            todos_productos.extend(productos)
            logger.info(f"Página {page}: {len(productos)} productos obtenidos")
            page += 1
            time.sleep(0.5)  # Evitar sobrecarga del servidor
        
        logger.info(f"Total productos WordPress: {len(todos_productos)}")
        return todos_productos
    
    def actualizar_producto_wordpress(self, producto_id: int, datos: Dict) -> bool:
        """Actualiza un producto en WordPress."""
        try:
            response = requests.put(
                f"{self.wp_url}/products/{producto_id}",
                auth=self.auth,
                json=datos,
                timeout=30
            )
            response.raise_for_status()
            return True
            
        except Exception as e:
            logger.error(f"Error al actualizar producto {producto_id}: {e}")
            return False
    
    def sincronizar(self):
        """Proceso principal de sincronización."""
        logger.info("=" * 60)
        logger.info("INICIANDO SINCRONIZACIÓN DE INVENTARIO")
        logger.info(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info("=" * 60)
        
        try:
            # Obtener datos de la API
            inventario_api = self.obtener_inventario_api()
            
            # Obtener productos de WordPress
            productos_wp = self.obtener_todos_productos_wordpress()
            self.stats['total_wp'] = len(productos_wp)
            
            # Procesar cada producto de WordPress
            for producto in productos_wp:
                self.procesar_producto(producto, inventario_api)
                time.sleep(0.3)  # Evitar sobrecarga
            
            # Mostrar resumen
            self.mostrar_resumen()
            
        except Exception as e:
            logger.error(f"Error en sincronización: {e}")
            raise
    
    def procesar_producto(self, producto: Dict, inventario_api: Dict):
        """Procesa y actualiza un producto individual."""
        producto_id = producto.get('id')
        nombre = producto.get('name', 'Sin nombre')
        sku = producto.get('sku', '').strip()
        
        if not sku:
            logger.warning(f"Producto {producto_id} ({nombre}) sin SKU - ignorado")
            self.stats['no_encontrados'] += 1
            return
        
        # Buscar en API
        if sku not in inventario_api:
            logger.info(f"SKU {sku} no encontrado en API - ignorado")
            self.stats['no_encontrados'] += 1
            return
        
        # Comparar y actualizar si es necesario
        datos_api = inventario_api[sku]
        stock_wp = producto.get('stock_quantity', 0) or 0
        precio_wp = float(producto.get('regular_price', 0) or 0)
        
        stock_api = datos_api['stock']
        precio_api = datos_api['precio']
        
        cambios = {}
        necesita_actualizacion = False
        
        # Verificar stock
        if stock_wp != stock_api:
            cambios['stock_quantity'] = stock_api
            cambios['manage_stock'] = True
            necesita_actualizacion = True
            logger.info(f"SKU {sku}: Stock {stock_wp} → {stock_api}")
        
        # Verificar precio
        if abs(precio_wp - precio_api) > 0.01:
            cambios['regular_price'] = str(precio_api)
            necesita_actualizacion = True
            logger.info(f"SKU {sku}: Precio {precio_wp} → {precio_api}")
        
        # Actualizar si hay cambios
        if necesita_actualizacion:
            if self.actualizar_producto_wordpress(producto_id, cambios):
                logger.info(f"✓ Producto {sku} actualizado exitosamente")
                self.stats['actualizados'] += 1
            else:
                logger.error(f"✗ Error al actualizar producto {sku}")
                self.stats['errores'] += 1
        else:
            self.stats['sin_cambios'] += 1
    
    def mostrar_resumen(self):
        """Muestra resumen de la sincronización."""
        logger.info("=" * 60)
        logger.info("RESUMEN DE SINCRONIZACIÓN")
        logger.info("=" * 60)
        logger.info(f"Total productos WordPress: {self.stats['total_wp']}")
        logger.info(f"Productos actualizados: {self.stats['actualizados']}")
        logger.info(f"Sin cambios: {self.stats['sin_cambios']}")
        logger.info(f"No encontrados en API: {self.stats['no_encontrados']}")
        logger.info(f"Errores: {self.stats['errores']}")
        logger.info("=" * 60)


def main():
    """Función principal."""
    try:
        sync = InventorySync()
        sync.sincronizar()
        logger.info("Sincronización completada exitosamente")
        
    except Exception as e:
        logger.error(f"Error fatal en sincronización: {e}")
        raise


if __name__ == "__main__":
    main()
