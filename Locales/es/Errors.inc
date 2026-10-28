{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{  Spanish error messages.                                      }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy                                  }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}

  FIBErrorMessages: array[TFIBClientError] of string = (
    'Error desconocido.',
    'Función no soportada.',
    'No permitido.',
    'Error de acceso al archivo temporal.',
    'Se agotó el tiempo de espera de la conexión a la base de datos.',
    'No se puede establecer la base de datos.',
    'No se puede establecer la transacción.',
    'Operación cancelada a petición del usuario.',
    'La constante DPB (isc_dpb_%s) no está soportada.',
    'La constante DPB (%s) es desconocida.',
    'La constante TPB (isc_tpb_%s) no está soportada.',
    'La constante TPB (%s) es desconocida.',
    '%s: No se puede realizar la operación -- la base de datos no está abierta.',
    'No se puede realizar la operación -- la base de datos está abierta.',
    'Falta el nombre de la base de datos.',
    '%s: La transacción no está activa.',
    '%s: La transacción está activa.',
    'Los valores de Timeout no pueden ser negativos.',
    '%s: No hay bases de datos en el componente de transacción.',
    '%s: Actualización en una base de datos incorrecta.',
    '%s: Actualización en una transacción incorrecta.',
    'No hay base de datos asignada para %s.',
    'No hay transacción asignada para %s.',
    'Índice XSQLDA fuera de rango.',
    'El nombre XSQLDA no existe (%s).',
    'Fin de archivo.',
    'Inicio de archivo.',
    '%s: Handle de sentencia no válido.',
    'No se puede %s porque el conjunto de datos %s está abierto.',
    'No se puede %s porque el conjunto de datos %s está cerrado.',
    'Tipo de datos SQL desconocido (%d).',
    'Índice de columna no válido (el índice supera el rango permitido).',
    'Índice de parámetro no válido (el índice supera el rango permitido).',
    'Conversión de datos no válida.',
    'La columna no puede ser null (%s)',
    'No se puede leer el flujo Blob.',
    'No se puede escribir en el flujo Blob.',
    'No se puede %s porque la consulta está vacía.',
    'No se puede ejecutar "open" en una sentencia que no es SELECT. Use ExecQuery.',
    'No hay acceso al campo "%s".',
    'El campo "%s" es de solo lectura.',
    'No se encontró el campo "%s".',
    'El conjunto de datos no está en modo Edit o Insert. (%s)',
    'No se está editando.',
    'No se puede insertar en el conjunto de datos. (%s)',
    'No se puede guardar (post). (%s)',
    'No se puede actualizar (update). (%s)',
    'No se puede eliminar del conjunto de datos. (%s)',
    'No se puede refrescar el registro (refresh). (%s)',
    'Búfer no establecido.',
    'No se permiten referencias circulares. (%s)',
    'Error de análisis SQL en '+':%s ' + CRLF + CRLF + '%s',
    'Cancelado por el usuario.',
    'El conjunto de datos es unidireccional.',
    'No se puede crear el recurso compartido. (error de Windows %d)',
    'Error de la API de Windows. (error de Windows %d [$%.8x])',
    'Las listas de columnas no coinciden.',
    'Los tipos de columna no coinciden. (Desde el índice: %d, hasta el índice: %d)',
    'Una transacción compartida solo se puede finalizar de forma forzada y con una acción igual a su TimeoutAction.',
    'La columna "%s" no es un campo de tipo array', // feNotIsArrayField
    'La dimensión %d no existe en "%s"', // feWrongDimension
    'Dialecto SQL no válido', // feSQLDialectInvalid
    'No se encontró la biblioteca cliente de Firebird. Instale el cliente de Firebird para usar esta funcionalidad', // feIBMissing
    '%s es una función de InterBase 6. Actualice a InterBase 6 para usar esta funcionalidad',
    'No se puede realizar la operación -- el servicio no está conectado',
    'No se puede realizar la operación -- el servicio está conectado',
    'Falta el nombre del servidor',
    'Los parámetros de consulta faltan o son incorrectos',
    'Los parámetros de inicio faltan o son incorrectos',
    'Valor inesperado en el búfer de salida',
    'ServiceStart genérico no aplicable: use los procedimientos específicos para establecer los parámetros de configuración',
    'Constante SPB no soportada',
    'Constante SPB desconocida',
    'Tamaño de campo demasiado pequeño. Campo %s.%s',
    '%s. No se puede usar la caché limitada. '#13#10 +
      'CachedUpdates debe ser False,'#13#10 +
      'Select debe tener la cláusula "Order by",'#13#10 +
      'Todos los campos de ordenación deben existir en la sección de campos'#13#10 +
      'Select no puede usar parámetros con el prefijo "NEW_"'#13#10 +
      'UpdateTransaction debe ser igual a Transaction o AutoCommit=True',
    'Error en %s. FieldList está vacío.',
    '%s no puede usar el campo "%s"',
    '%s es una función de Firebird 2. Actualice a Firebird 2 para usar esta funcionalidad',
    '%s no está soportado por %s',
    '%s no está soportado por la biblioteca cliente %s',
    'No se encontró la columna array %s.%s',
    'Array %s.%s: el nombre %s es demasiado largo',
    'El array %s.%s tiene %d dimensión(es), se dieron %d índice(s)',
    'Array %s.%s: no se puede convertir "%s" al tipo de los elementos',
    'Array %s.%s: el tipo de elemento %d no está soportado',
    'Array %s.%s: la cadena "%s" tiene más de %d bytes',
    'Array %s.%s: el valor no es un array',
    'El array %s.%s tiene %d dimensión(es), el valor tiene %d',
    'Array %s.%s: el valor tiene %d bytes en lugar de %d',
    'Array %s.%s: el índice %d está fuera de los límites %d:%d de la dimensión %d',
    'Array %s.%s: los límites %d:%d de la dimensión %d no caben en TISC_ARRAY_BOUND',
    'Array %s.%s: la dimensión %d tiene %d elemento(s), el valor tiene %d',
    'El parámetro %s no es un array',
    'La página de códigos %d no está disponible en este sistema',
    'No se puede convertir el carácter entre juegos de caracteres: "%s" a la página de códigos %d',
    '%s: No se encontró o no se pudo analizar la cláusula ORDER BY.',
    '%s.' + CRLF + 'El campo %s se usa en la ordenación, pero no está en los campos de SelectSQL',
    '%s: No se pueden cargar los metadatos.',
    'El valor de %s tiene %d bytes, el máximo es %d',
    'Valor no válido "%s" en %s',
    'Archivo de blobs %s, parámetro %s: %s'
  );
