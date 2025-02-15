#!/bin/bash

# ###############################################
# SCRIPT:   mysql_backup.sh
# VERSIÓN:  1.3
# FECHA:    17-10-2024
# AUTOR:    DIEGO RODERO PULIDO
# ###############################################
# INFO:     Este script realiza automaticamente un backup de todas las bases de datos del servidor.
#           Una vez completado el backup, comprueba que está bien hecho y lo comprime.
#           Si detecta error, manda un email de aviso con el mismo a la dirección proporcionada.
#           Al finalizar, manda también un mail con un resumen de lo acontecido
#   1.1     Con una nueva variable (CHECK_SLAVE), indico si comprobar el estado de esclavo o no.
#           Cambio la viariable SERVIDOR por HOSTNAME que tiene el sistema
#   1.2     Copia los ficheros terminados a una unidad de red de copia
#   1.3     Añadida la opción de especificar el remitente del email
# ###############################################

VERSION="1.2"

# ###############################################
# VARIABLES DEL SCRIPT 
# ###############################################

source script_config.cnf

# ###############################################
# ###############################################
# ###############################################

# FICHERO DE LOG
FECHA=$(date +%Y-%m-%d-%H.%M.%S)
FICHERO_LOG="$RUTA_LOGS/$FECHA-backup_db.log"
touch $FICHERO_LOG

BDS_CORRECTAS=0
BDS_ERROR=0

# FUNCIÓN BACKUP
function BACKUP {

        FECHA=$(date +%Y-%m-%d-%H.%M.%S)
        BASEDEDATOS=$1
        FICHERO_SQL="$RUTA_BACKUP/$BASEDEDATOS/$BASEDEDATOS"_"$FECHA.sql"       
        
        LOG "INICIO $BASEDEDATOS --> $FICHERO_SQL.gz"   

        if [ ! -d "$RUTA_BACKUP/$BASEDEDATOS" ]; then
            mkdir $RUTA_BACKUP/$BASEDEDATOS
        fi

        mysqldump --defaults-extra-file=$FICHERO_CONFIG_MYSQL $BASEDEDATOS --add-drop-database --lock-tables=false --routines --events  > $FICHERO_SQL 2>> $FICHERO_LOG

        RESULTADO="$(tail -n1 $FICHERO_SQL)"

        RES=${RESULTADO} 

        if [[ $RES == *"Dump completed"* ]]
             then
                gzip $FICHERO_SQL 2>> $FICHERO_LOG
                FILESIZE=$(du -h $FICHERO_SQL.gz | cut -f1)
                LOG "     [OK] $FILESIZE"                
                BDS_CORRECTAS=$((BDS_CORRECTAS + 1))
                COPIA_REMOTO "$FICHERO_SQL.gz"
             else
                BDS_ERROR=$((BDS_ERROR + 1))
                LOG " +#+# [ERROR] $BASEDEDATOS | $FICHERO_SQL | [DUMP] $RES"
                mail -a$EMAILREMITENTE -s "Error de copia de BD $HOSTNAME - $BASEDEDATOS" $EMAILAVISO -r $EMAILREMITENTE <<< $"Error de copia de BD 
$HOSTNAME - $BASEDEDATOS
Fecha:      $FECHA
Fichero:    $FICHERO_SQL
Texto:      $RES" 2>> $FICHERO_LOG
        fi"

}

function COPIA_REMOTO {

}

# FUNCION LOG: AÑADE UNA NUEVA LINEA AL LOG CON LA FECHA
function LOG {
    MENSAJE=$"[$(date +%Y-%m-%d-%H.%M.%S)] $1" 
    echo $MENSAJE >> $FICHERO_LOG
    echo $MENSAJE
}

# ###############################################
# ###############################################
# ###############################################

LOG "COMIENZA EL SCRIPT PARA $HOSTNAME. VERSIÓN $VERSION"

# ME TRAIGO LA LISTA DE LAS BASES DE DATOS DEL SERVIDOR
LISTA_BDS=`echo 'show databases' | mysql --defaults-extra-file=$FICHERO_CONFIG_MYSQL -B | sed /^Database$/d`

# PARA CADA BASE DE DATOS, REALIZAMOS UN BACKUP
for DB in $LISTA_BDS
do
  if [ "$DB" == "information_schema" ] || [ "$DB" == "mysql" ] || [ "$DB" == "performance_schema" ] || [ "$DB" == "sys" ]; then      
        # NO HACEMOS NADA  
        NADA=""
  else
        BACKUP $DB 
  fi  
done

# REALIZAMOS UNA COPIA ADICIONAL DE TODAS LAS BASES DE DATOS
BACKUP "--all-databases"


# COMPRUEBO EL ESTADO DEL ESCLAVO Y LO PINTO EN EL LOG 
ESTADO_ESCLAVO = "";

if [ $CHECK_SLAVE = true ] ; then
    ESTADO_ESCLAVO=`echo 'show slave status\G' | mysql --defaults-extra-file=$FICHERO_CONFIG_MYSQL | grep Slave_SQL_Running_State`
    LOG $ESTADO_ESCLAVO

    ESTADO_ESCLAVO = "ESCLAVO: $ESTADO_ESCLAVO"
fi

LOG "TERMINA EL SCRIPT PARA $HOSTNAME"

# ENVIAMOS UN EMAIL DE RESUMEN DEL ESTADO DE LA COPIA
mail -a$EMAILREMITENTE -s "Copia completada de BD $HOSTNAME" $EMAILAVISO -A $FICHERO_LOG <<< "
FECHA: $(date +%Y-%m-%d-%H.%M.%S)
SERVIDOR: $HOSTNAME
$ESTADO_ESCLAVO
COPIAS CORRECTAS: $BDS_CORRECTAS
COPIAS CON ERROR: $BDS_ERROR


----------------------------
VERSION DEL SCRIPT: $VERSION"  2>> $FICHERO_LOG




