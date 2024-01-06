#!/bin/bash
################################################################################
# Script for installing Odoo on Ubuntu 14.04, 15.04, 16.04 and 18.04 (could be used for other version too)
# Author: Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 16.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################

OE_USER="odoo"
OE_HOME="/$OE_USER"
OE_HOME_EXT="/$OE_USER/${OE_USER}-server"
# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"
# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
# Choose the Odoo version which you want to install. For example: 13.0, 12.0, 11.0 or saas-18. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 13.0
OE_VERSION="17.0"
# Set this to True if you want to install the Odoo enterprise version!
IS_ENTERPRISE="True"
# Set this to True if you want to install Nginx!
INSTALL_NGINX="True"
# Set the superadmin password - if GENERATE_RANDOM_PASSWORD is set to "True" we will automatically generate a random password, otherwise we use this one
OE_SUPERADMIN="admin"
# Set to "True" to generate a random password, "False" to use the variable in OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="False"
OE_CONFIG="${OE_USER}-server"
# Set the website name
WEBSITE_NAME="http://216.126.231.159"
# Set the default Odoo longpolling port (you still have to use -c /etc/odoo-server.conf for example to use this.)
LONGPOLLING_PORT="8072"
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Provide Email to register ssl certificate
ADMIN_EMAIL="ayamkentz@gmail.com"

# Set Custom Modules
OCA="True"
SAAS="True"
CybroOdoo="True"
MuKIT="True"
SythilTech="True"
odoomates="True"
openeducat="True"
Openworx="True"
JayVoraSerpentCS="True"
##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/13.0/setup/install.html#debian-ubuntu

WKHTMLTOX_X64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_amd64.deb"
WKHTMLTOX_X32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.$(lsb_release -c -s)_i386.deb"
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
# universe package is for Ubuntu 18.x
sudo add-apt-repository universe
# libpng12-0 dependency for wkhtmltopdf
# sudo add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ xenial main"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install libpq-dev

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
#echo -e "\n---- Install PostgreSQL Server ----"
#sudo apt-get install postgresql postgresql-server-dev-all -y

#echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
#sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt-get install python3 python3-pip
sudo apt-get install git python3-cffi build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng-dev libjpeg-dev gdebi -y

echo -e "\n---- Install python packages/requirements ----"
sudo -H pip3 install -r https://github.com/odoo/odoo/raw/${OE_VERSION}/requirements.txt

echo -e "\n---- Installing nodeJS NPM and rtlcss for LTR support ----"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
# if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
#   echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 13 ----"
#   #pick up correct one from x64 & x32 versions:
#   if [ "`getconf LONG_BIT`" == "64" ];then
#       _url=$WKHTMLTOX_X64
#   else
#       _url=$WKHTMLTOX_X32
#   fi
#   sudo wget $_url
#   sudo gdebi --n `basename $_url`
sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
# else
#   echo "Wkhtmltopdf isn't installed due to the choice of the user!"
# fi

echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n---- Create Log directory ----"
sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n--- Create symlink for node"
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "------------------------WARNING------------------------------"
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "-------------------------------------------------------------"
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n---- Added Enterprise code under $OE_HOME/enterprise/addons ----"
    echo -e "\n---- Installing Enterprise specific libraries ----"
    sudo -H pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n---- Create custom module directory ----"
sudo su $OE_USER -c "mkdir $OE_HOME/custom"
sudo su $OE_USER -c "mkdir $OE_HOME/custom/addons"

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"


sudo touch /etc/${OE_CONFIG}.conf
echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${OE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generating random admin password"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> /etc/${OE_CONFIG}.conf"
if [ $OE_VERSION > "11.0" ];then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> /etc/${OE_CONFIG}.conf"

if [ $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons\n' >> /etc/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons\n' >> /etc/${OE_CONFIG}.conf"
fi
sudo chown $OE_USER:$OE_USER /etc/${OE_CONFIG}.conf
sudo chmod 640 /etc/${OE_CONFIG}.conf

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
DAEMON=$OE_HOME_EXT/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="/etc/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults



#--------------------------------------------------
# Adding ODOO as a Modules (initscript)
#--------------------------------------------------
echo -e "install odoo Modules"
cd  $OE_HOME/custom
if [ $OCA = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-analytic.git oca/account-analytic")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-budgeting.git oca/account-budgeting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-closing.git oca/account-closing")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-consolidation.git oca/account-consolidation")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-financial-reporting.git oca/account-financial-reporting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-financial-tools.git oca/account-financial-tools")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-fiscal-rule.git oca/account-fiscal-rule")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-invoice-reporting.git oca/account-invoice-reporting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-invoicing.git oca/account-invoicing")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-payment.git oca/account-payment")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/account-reconcile.git oca/account-reconcile")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/bank-payment.git oca/bank-payment")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/bank-statement-import.git oca/bank-statement-import")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/commission.git oca/commission")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/community-data-files.git oca/community-data-files")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/connector.git oca/connector")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/connector-telephony.git oca/connector-telephony")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/contract.git oca/contract")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/credit-control.git oca/credit-control")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/crm.git oca/crm")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/currency.git oca/currency")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/data-protection.git oca/data-protection")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/ddmrp.git oca/ddmrp")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/delivery-carrier.git oca/delivery-carrier")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/e-commerce.git oca/e-commerce")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/edi.git oca/edi")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/event.git oca/event")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/field-service.git oca/field-service")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/geospatial.git oca/geospatial")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/hr.git oca/hr")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/timesheet.git oca/timesheet")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/iot.git oca/iot")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/knowledge.git oca/knowledge")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/management-system.git oca/management-system")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/manufacture.git oca/manufacture")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/manufacture-reporting.git oca/manufacture-reporting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/margin-analysis.git oca/margin-analysis")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/mis-builder.git oca/mis-builder")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/multi-company.git oca/multi-company")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/operating-unit.git oca/operating-unit")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/partner-contact.git oca/partner-contact")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/pos.git oca/pos")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/product-attribute.git oca/product-attribute")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/product-kitting.git oca/product-kitting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/product-variant.git oca/product-variant")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/project.git oca/project")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/project-reporting.git oca/project-reporting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/purchase-reporting.git oca/purchase-reporting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/purchase-workflow.git oca/purchase-workflow")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/queue.git oca/queue")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/reporting-engine.git oca/reporting-engine")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/report-print-send.git oca/report-print-send")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/sale-financial.git oca/sale-financial")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/sale-reporting.git oca/sale-reporting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/sale-workflow.git oca/sale-workflow")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/server-auth.git oca/server-auth")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/server-backend.git oca/server-backend")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/server-brand.git oca/server-brand")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/server-env.git oca/server-env")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/server-tools.git oca/server-tools")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/server-ux.git oca/server-ux")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/social.git oca/social")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/stock-logistics-barcode.git oca/stock-logistics-barcode")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/stock-logistics-reporting.git oca/stock-logistics-reporting")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/stock-logistics-tracking.git oca/stock-logistics-tracking")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/stock-logistics-transport.git oca/stock-logistics-transport")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/stock-logistics-warehouse.git oca/stock-logistics-warehouse")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/stock-logistics-workflow.git oca/stock-logistics-workflow")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/vertical-community.git oca/vertical-community")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/vertical-construction.git oca/vertical-construction")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/vertical-edition.git oca/vertical-edition")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/vertical-hotel.git oca/vertical-hotel")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/vertical-isp.git oca/vertical-isp")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/vertical-ngo.git oca/vertical-ngo")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/vertical-travel.git oca/vertical-travel")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/web.git oca/web")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/webkit-tools.git oca/webkit-tools")
  REPOS=( "${REPOS[@]}" "https://github.com/oca/website.git oca/website")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/storage.git oca/storage")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/brand.git oca/brand")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/rest-framework.git oca/rest-framework")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/connector-jira.git oca/connector-jira")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/search-engine.git oca/search-engine")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/helpdesk.git oca/helpdesk")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/product-pack.git oca/product-pack")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/payroll.git oca/payroll")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/wms.git oca/wms")
  REPOS=( "${REPOS[@]}" "https://github.com/OCA/dms.git oca/dms")


fi
if [ $SAAS = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/e-commerce.git it-projects-llc/e-commerce")
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/pos-addons.git it-projects-llc/pos-addons")
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/access-addons.git it-projects-llc/access-addons")
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/website-addons.git it-projects-llc/website-addons")
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/misc-addons.git it-projects-llc/misc-addons")
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/mail-addons.git it-projects-llc/mail-addons")
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/odoo-saas-tools.git it-projects-llc/odoo-saas-tools")
  REPOS=( "${REPOS[@]}" "https://github.com/it-projects-llc/odoo-telegram.git it-projects-llc/odoo-telegram")
fi
if [ $CybroOdoo = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/CybroOdoo/CybroAddons.git CybroOdoo/CybroAddons")
  REPOS=( "${REPOS[@]}" "https://github.com/CybroOdoo/OpenHRMS.git CybroOdoo/OpenHRMS")
fi
if [ $MuKIT = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_base.git mukit/muk_base")
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_web.git mukit/muk_web")
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_bundles.git mukit/muk_bundles")
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_website.git mukit/muk_website")
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_misc.git mukit/muk_misc")
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_dms.git mukit/muk_dms")
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_docs.git mukit/muk_docs")
  REPOS=( "${REPOS[@]}" "https://github.com/muk-it/muk_quality.git mukit/muk_quality")
fi
if [ $SythilTech = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/SythilTech/Odoo.git SythilTech/Odoo")
fi
if [ $odoomates = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/odoomates/odooapps.git odoomates/odooapps")
fi
if [ $openeducat = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/openeducat/openeducat_erp.git openeducat/openeducat_erp")
fi
if [ $JayVoraSerpentCS = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/JayVora-SerpentCS/OdooHotelManagementSystem.git JayVora-SerpentCS/OdooHotelManagementSystem")
  REPOS=( "${REPOS[@]}" "https://github.com/JayVora-SerpentCS/SerpentCS_Contributions.git JayVora-SerpentCS/SerpentCS_Contributions")
  REPOS=( "${REPOS[@]}" "https://github.com/JayVora-SerpentCS/Jasperreports_odoo.git JayVora-SerpentCS/Jasperreports_odoo")
  REPOS=( "${REPOS[@]}" "https://github.com/JayVora-SerpentCS/MassEditing.git JayVora-SerpentCS/MassEditing")
  REPOS=( "${REPOS[@]}" "https://github.com/JayVora-SerpentCS/fleet_management.git JayVora-SerpentCS/fleet_management")
  REPOS=( "${REPOS[@]}" "https://github.com/JayVora-SerpentCS/DOST.git JayVora-SerpentCS/DOST")
  REPOS=( "${REPOS[@]}" "https://github.com/JayVora-SerpentCS/Community_Portal.git JayVora-SerpentCS/Community_Portal")

fi
if [ $Openworx = "True" ]; then
  REPOS=( "${REPOS[@]}" "https://github.com/Openworx/odoo-addons.git Openworx/odoo-addons")
  REPOS=( "${REPOS[@]}" "https://github.com/Openworx/backend_theme.git Openworx/backend_theme")
fi
 if [[ "${REPOS}" != "" ]]
 then
     apt-get install -y git
 fi

 for r in "${REPOS[@]}"
 do
     eval "git clone --depth=1 -b ${OE_VERSION} $r" || echo "Cannot clone: git clone -b ${OE_VERSION} $r"
 done

 if [[ "${REPOS}" != "" ]]
 then
     chown -R ${OE_USER}:${OE_USER} $OE_HOME/custom || true
 fi
      ADDONS_PATH=`ls -d1 /odoo/custom/*/* | tr '\n' ','`
      ADDONS_PATH=`echo /odoo/odoo-server/addons,/odoo/custom/addons,$ADDONS_PATH | sed "s,//,/,g" | sed "s,/,\\\\\/,g" | sed "s,.$,,g" `
     sed -ibak "s/addons_path.*/addons_path = $ADDONS_PATH/" /etc/odoo-server.conf

echo -e "install odoo requirements"
 sudo pip3 install wheel
 #sudo apt install libldap2-dev libsasl2-dev
 #sudo pip3 install pyldap
 #sudo pip3 install -r /$OE_USER/$OE_CONFIG/requirements.txt
 #sudo pip3 install configparser
 #sudo pip3 install future
 #pip3 install num2words
 #pip3 install PyXB
 #pip3 install mysql-connector-python
 #pip3 install -r oca/account-analytic/requirements.txt
 #pip3 install -r oca/account-budgeting/requirements.txt
 


echo -e "* Starting Odoo Service"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "Configuraton file location: /etc/${OE_CONFIG}.conf"
echo "Logfile location: /var/log/$OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Password superadmin (database): $OE_SUPERADMIN"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
if [ $INSTALL_NGINX = "True" ]; then
  echo "Nginx configuration file: /etc/nginx/sites-available/odoo"
fi
echo "-----------------------------------------------------------"
