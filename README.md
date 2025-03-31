# Proyecto ETL - Data Warehouse Northwind

## Descripción
Implementación de Fact Tables para el almacén de datos Northwind, incluyendo:
- FactOrders
- FactCustomers (clientes atendidos)
- FactOrderDetails

## Contenido del Repositorio
1. **SSIS_Package/**: Paquete de Integration Services (`Load_FactTables.dtsx`)
2. **SQL_Scripts/**: Scripts SQL completos para creación de tablas y procedimientos
3. **Documentation/**: 
   - Informe PDF con capturas del proceso
   - Evidencias de ejecución exitosa

## Requisitos Previos
- SQL Server con base de datos Northwind
- SQL Server Data Tools (SSDT)
- SQL Server Integration Services

## Instrucciones de Implementación
1. Ejecutar el script SQL completo (`Northwind_DW_ETL_Scripts.sql`)
2. Abrir el paquete SSIS en Visual Studio
3. Configurar las conexiones:
   - `Northwind_Source`: Conexión a la base Northwind
   - `dwventas_Target`: Conexión al data warehouse
4. Ejecutar el paquete `Load_FactTables.dtsx`

## Validación
Después de ejecutar, verificar con:
```sql
USE dwventas
SELECT 
    (SELECT COUNT(*) FROM FactOrders) AS Orders,
    (SELECT COUNT(*) FROM FactCustomers) AS Customers,
    (SELECT COUNT(*) FROM FactOrderDetails) AS OrderDetails