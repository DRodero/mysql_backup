#!/bin/bash

# ###############################################
# SCRIPT:   mysql_backup.sh
# VERSIÓN:  1.0
# FECHA:    06-12-2016
# AUTOR:    DIEGO RODERO PULIDO
# ###############################################
# INFO:     Este script realiza automaticamente un backup de todas las bases de datos del servidor.
#           Una vez completado el backup, comprueba que está bien hecho y lo comprime.
#           Si detecta error, manda un email de aviso con el mismo a la dirección proporcionada.
#           Al finalizar, manda también un mail con un resumen de lo acontecido
# ###############################################

VERSION="1.0"

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

        if [ ! -d "$DIRECTORY" ]; then
            mkdir $RUTA_BACKUP/$BASEDEDATOS
        fi

        # mysqldump --add-drop-database --lock-tables=false --routines --events -u$USUARIO -p$PASSWORD $BASEDEDATOS $2 > $FICHERO_SQL
        mysqldump --defaults-extra-file=$FICHERO_CONFIG_MYSQL $BASEDEDATOS --add-drop-database --lock-tables=false --routines --events  > $FICHERO_SQL

        RESULTADO="$(tail -n1 $FICHERO_SQL)"

        RES=${RESULTADO} 

        if [[ $RES == *"Dump completed"* ]]
             then
                gzip $FICHERO_SQL
                FILESIZE=$(du -h $FICHERO_SQL.gz | cut -f1)
                LOG "     [OK] $FILESIZE"                
                BDS_CORRECTAS=$((BDS_CORRECTAS + 1))
             else
                BDS_ERROR=$((BDS_ERROR + 1))
                LOG " **** [ERROR] $BASEDEDATOS | $FICHERO_SQL | [DUMP] $RES"
                mail -s "Error de copia de BD $SERVIDOR - $BASEDEDATOS" $EMAILAVISO <<< $"Error de copia de BD 
$SERVIDOR - $BASEDEDATOS
Fecha:      $FECHA
Fichero:    $FICHERO_SQL
Texto:      $RES"
        fi

}

# FUNCION LOG: AÑADE UNA NUEVA LINEA AL LOG CON LA FECHA
function LOG {
    MENSAJE=$"[$(date +%Y-%m-%d %H.%M.%S)] $1" 
    echo $MENSAJE >> $FICHERO_LOG
    echo $MENSAJE
}

# ###############################################
# ###############################################
# ###############################################

LOG "COMIENZA EL SCRIPT PARA $SERVIDOR. VERSIÓN $VERSION"

# ME TRAIGO LA LISTA DE LAS BASES DE DATOS DEL SERVIDOR

LISTA_BDS=`echo 'show databases' | mysql --defaults-extra-file=$FICHERO_CONFIG_MYSQL -B | sed /^Database$/d`

# PARA CADA BASE DE DATOS, LE REALIZO UN BACKUP

for DB in $LISTA_BDS
do
  if [ "$DB" == "information_schema" ] || [ "$DB" == "performance_schema" ]; then      
        # NO HACEMOS NADA  
        NADA=""
  else
        BACKUP $DB 
  fi  
done


LOG "TERMINA EL SCRIPT PARA $SERVIDOR"

mail -s "Copia completada de BD $SERVIDOR" $EMAILAVISO -A $FICHERO_LOG <<< "
FECHA: $(date +%Y-%m-%d-%H.%M.%S)
SERVIDOR: $SERVIDOR
COPIAS CORRECTAS: $BDS_CORRECTAS
COPIAS CON ERROR: $BDS_ERROR


----------------------------
VERSION DEL SCRIPT: $VERSION"

cat $FICHERO_LOG


