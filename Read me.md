# Práctica IAW 1

# Instalación de la pila LAMP en una máquina Ubuntu Server

## Pasos previos
Primero creamos una máquina virtual de Ubuntu Server.

Cuando la máquina esté lista para usarla iniciamos sesión y lo primero que haremos será establecer una dirección IP estática ya que por el momento estamos utilizando el cliente DHCP, no se explicará como hacerlo ya que no forma parte de la práctica.

En mi caso además estoy conectándome a la máquina haciendo uso de SSH porque así se me hace más sencillo el uso de la misma.

Sin más preámbulos, pasamos a la práctica.

>Nota. En vez de ejecutar los comandos en modo administrador poniendo sudo cada vez que se introduzca uno, se pondrá el modo super usuario con el comando sudo su, que, para aclarar, permite al usuario pasar al estado de administrador o root.


## Instalando Apache HTTP Server

Antes de instalarlo vamos a asegurarnos de que la lista de repositiorios y paquetes está actualizado, para ello hacemos uso del comando:

>sudo apt update

Si hay nuevos paquetes para instalar, utilizamos el siguiente comando:

>sudo apt upgrade

Una vez hayamos actualizado los paquetes instalamos el servidor Apache.

>sudo apt install apache2 -y

Añadimos el -y para que omita cualquier interacción con el ususario y la instalación pueda ser directa.

Para comprobar que se ha instalado podemos entrar en la dirección IP de nuestra máquina servidora y veremos que se nos muestra la página principal de Apache.

## Instalando PHP

Para instalar PHP utilizaremos un comando con el que instalaremos php y sus herramientas:

>sudo apt install php libapache2-mod-php php-mysql

Si queremos comprobar que se ha instalado vamos al archivo /var/www/html/info.php y con el editor de texto agregamos las siuientes líneas:

```php
<?php
phpinfo();
?>
```

Después de esto abrimos nuestro navegador y ponemos nuestra dirección IP/info.php veremos un documento en el que se nos enseñará toda la información php del servidor.

## Instalando MySQL Server

Ingresamos el comando:

>sudo apt install mysql-server -y

No tendremos que hacer nada más, si queremos comprobar que se nos ha instalado podemos acceder al servidor MySQL con el comando:

>sudo mysql -u root

Y entraremos al servidor.

Podemos cambiar la contraseña del servidor, esto se ha realizado fuera del trabajo y en el cscript vienen los comandos utilizados

## Instalación de la aplicación web propuesta

Primero vamos a la carpeta en la que vamos a instalar la aplicación con el comando:

>cd /var/www/html

Para futuras reinstalaciones y demás, nos aseguraremos de que el directorio de la aplicación no existe eliminándola en caso de que esté creado con el comando:

>sudo rm -rf iaw-practica-lamp

Ahora descargamos el repositorio de Github

>git clone https://github.com/josejuansanchez/iaw-practica-lamp.git


Y movemos el contenido del repositorio a la carpeta Apache

>mv /var/www/html/iaw-practica-lamp/src/* /var/www/html/

Después debemos eliminar el archivo index.html de Apache para que cuando entremos al servidor se muestre la aplicación web

>rm -rf /var/www/html/index.html

Por último haremos dos pasos, crear el script para la base de datos de la aplicación, y segundo eliminar el directorio iaw-practica-lamp porque ya no lo necesitaremos

>mysql -u root -p$DB_ROOT_PASSWD < /var/www/html/iaw-practica-lamp/db/database.sql

>rm -rf /var/www/html/iaw-practica-lamp/

## Instalar Adminer

Primero creamos el directorio de instalación

>mkdir /var/www/html/adminer

Nos movemos al directorio y descargamos su repositorio de Github

>cd /var/www/html/adminer

>wget https://github.com/vrana/adminer/releases/download/v4.7.7/adminer-4.7.7-mysql.php

Movemos los ficheros php al directorio de Apache

>mv adminer-4.7.7-mysql.php index.php

Y como último paso nos vamos al directorio de Apache y cambiamos los permisos

>cd /var/www/html

>chown www-data:www-data * -R

## Instalando GoAccess

Abrimos el archivo de repositorios de ubuntu y agregamos el siguiente repositorio

>deb http://deb.goaccess.io/

Conseguimos la clave de la aplicación

>wget -O - https://deb.goaccess.io/gnugpg.key | sudo apt-key add -

Por último actualizamos nuestra lista de paquetes e instalamos GoAccess

>apt update -y

>apt install goaccess -y

## Configurando el control de acceso

Creamos un directorio en el que instalaremos el stats en Apache

>mkdir /var/www/html/stats

Dejamos a GoAcces ejecutándose en segundo plano

>nohup goaccess /var/log/apache2/access.log -o /var/www/html/stats/index.html --log-format=COMBINED --real-time-html &

Creamos un archivo en el que estarán las contraseñas del usuario que accederá al directorio

>htpasswd -b -c $HTTPASSWD_DIR/.htpasswd $HTTPASSWD_USER $HTTPASSWD_PASSWD

Reemplazamos las cadenas correspondientes de PATH

>sed -i 's#REPLACE_THIS_PATH#$HTTPASSWD_DIR#g' $HTTPASSWD_DIR/000-default.conf

Copiamos el archivo de configuración del usuario

>cp $HTTPASSWD_DIR/000-default.conf /etc/apache2/sites-available/

Y para finalizaar reiniciamos Apache

>systemctl restart apache2

## Instalar AWStats

Ejecutamos el comando de instalación

>apt install awstats -y

Cambiamos los valores LogFormat y SiteDomain en el archivo de configuración

>sed -i 's/LogFormat=4/LogFormat=1/g' /etc/awstats/awstats.conf

>sed -i 's/SiteDomain=""/SiteDomain="practicaiaw.com"/g' /etc/awstats/awstats.conf

Copiamos el archivo modificado del usuario al directorio /etc/apache2/conf-available/

>cp $HTTPASSWD_DIR/awstats.conf /etc/apache2/conf-available/

Activamos el servicio AWStats

>a2enconf awstats serve-cgi-bin

>a2enmod cgi

Reiniciamos Apache, y ajustamos los permisos y actualizamos los logs de la web

>systemctl restart apache2

>sed -i -e "s/www-data/root/g" /etc/cron.d/awstats /usr/share/awstats/tools/update.sh

Nota:

Algunas partes finales de la práctica me han resultado difíciles y le he pedido a Adrián Ramírez permiso para poder echar un vistazo a su script con el fin de tener una referencia y no estar tan perdido.