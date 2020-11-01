#!/bin/bash

#Declarar todas las variables de utilidad
DB_ROOT_PASSWD=root
PHPMYADMIN_PASSWD=`tr -dc A-Za-z0-9 < /dev/urandom | head -c 64`
HTTPASSWD_DIR=/home/ubuntu
HTTPASSWD_USER=usuario
HTTPASSWD_PASSWD=usuario

#Activar la depuración del script
set -x

#Actualizar lista de paquetes Ubuntu
apt update -y

#Actualizar los paquetes instalados
apt upgrade -y

#-------------------------
#Instalar servidor Apache |
#-------------------------
apt install apache2 -y
#--------------------------------------------------------------

#----------------------
#Instalar MySQLServer |
#----------------------
apt install mysql-server -y

#Cambiamos la contraseña root del servidor
mysql -u root <<< "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$DB_ROOT_PASSWD';"
mysql -u root <<< "FLUSH PRIVILEGES;"

#--------------------------------------------------------------

#------------------------------
#Instalar php y sus utilidades |
#------------------------------
apt install php libapache2-mod-php php-mysql -y

#Crear el archivo info.php con el contenido necesario
echo "<?php
phpinfo();
?>" >> /var/www/html/info.php
#--------------------------------------------------------------

#--------------------
#Instalar phpmyadmin|
#--------------------

#Crear los volcados de configuración previos durante la instalación
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWD" |debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWD" | debconf-set-selections

#Instalar phpmyadmin
apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

#--------------------------------------------------------------

#-----------------------------------
#Instalar aplicación web propuesta |
#-----------------------------------

#Vamos al directorio en el que se instalará la aplicación
cd /var/www/html

#Por si la carpeta de la aplicación existe, ejecutaremos una orden para que sea eliminada
rm -rf iaw-practica-lamp

#Descargamos el repositorio
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git

#Movemos el contenido del repositorio a la carpeta de Apache
mv /var/www/html/iaw-practica-lamp/src/* /var/www/html/

#Quitar index.html para que al entrar se muestre ota página
rm -rf /var/www/html/index.html

#Conseguimos el script de creación para la base de datos
mysql -u root -p$DB_ROOT_PASSWD < /var/www/html/iaw-practica-lamp/db/database.sql

#Quitamos los archivos que no necesitamos
rm -rf /var/www/html/iaw-practica-lamp/

#--------------------------------------------------------------

#-----------------
#Instalar Adminer |
#-----------------

#Creamos el directorio de Apache donde irá instalado
mkdir /var/www/html/adminer

#Cambiamos al directorio de Adminer
cd /var/www/html/adminer

#Descargamos su repositorio de Github
wget https://github.com/vrana/adminer/releases/download/v4.7.7/adminer-4.7.7-mysql.php

#Movemos el contenido de la aplicación
mv adminer-4.7.7-mysql.php index.php

#Cambiamos los permisos del directorio Apache
cd /var/www/html
chown www-data:www-data * -R

#--------------------------------------------------------------

#------------------
#Instalar GoAccess |
#------------------
echo "deb http://deb.goaccess.io/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/goaccess.list

#Descargamos las claves y el certificado necesario
wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key add -

#Instalar GoAccess
apt update -y
apt install goaccess -y

#--------------------------------------------------------------

#------------------
#Control de acceso |
#------------------

#Creamos un nuevo directorio llamado stats en el directorio de apache
mkdir /var/www/html/stats

#Hacemos que el proceso de goaccess se ejecute en background y que genere los informes en segundo plano.
nohup goaccess /var/log/apache2/access.log -o /var/www/html/stats/index.html --log-format=COMBINED --real-time-html &

#Creamos el archivo de contraseñas para el usuario que accederá al directorio stats y lo guardamos en un directorio seguro. 
#En nuestro caso el archivo se va a llamar .htpasswd y se guardará en el directorio /home/usuario. 
#El usuario que vamos a crear tiene como nombre de usuario: usuario.
htpasswd -b -c $HTTPASSWD_DIR/.htpasswd $HTTPASSWD_USER $HTTPASSWD_PASSWD

#Cambiamos la cadena "REPLACE_THIS_PATH" por la ruta de la carpeta del usuario
sed -i 's#REPLACE_THIS_PATH#$HTTPASSWD_DIR#g' $HTTPASSWD_DIR/000-default.conf

#Copiamos el archivo de configuracion de Apache desde el directorio de usuario

cp $HTTPASSWD_DIR/000-default.conf /etc/apache2/sites-available/

#Reiniciamos el servicio Apache
systemctl restart apache2

#--------------------------------------------------------------

#----------------------------
#Ampliación: Instalar AWStats|
#----------------------------
apt install awstats -y

#Cambiamos el valor LogFormat y SiteDomain en el archivo de configuración predeterminado
sed -i 's/LogFormat=4/LogFormat=1/g' /etc/awstats/awstats.conf
sed -i 's/SiteDomain=""/SiteDomain="practicaiaw.com"/g' /etc/awstats/awstats.conf

#Copiamos el archivo de configuración web ya modificado del directorio de usuario al directorio de /etc/apache2/conf-available/
cp $HTTPASSWD_DIR/awstats.conf /etc/apache2/conf-available/

#Activamos AwStats
a2enconf awstats serve-cgi-bin
a2enmod cgi

#Reiniciamos Apache
systemctl restart apache2

#Ajustamos los permisos y actualizamos los logs
sed -i -e "s/www-data/root/g" /etc/cron.d/awstats
/usr/share/awstats/tools/update.sh