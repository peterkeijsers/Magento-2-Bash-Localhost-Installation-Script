if [ -e config.sh ]
then
    source config.sh
else
    source config.sample.sh
fi

NAME=$1
EDITION=$2
OPTIONS=${@:3}

if [ -z "$NAME" ]; then
	echo "enter name. Will be used as  $DOMAIN_PREFIX<yourname>$DOMAIN_SUFFIX"
	exit;
fi

DOMAIN=$DOMAIN_PREFIX$NAME$DOMAIN_SUFFIX
DIRECTORY=$DOMAINS_PATH/$DOMAIN
MYSQL_DATABASE_NAME=$MYSQL_DATABASE_PREFIX$NAME

if [ -d "$DIRECTORY" ]; then
        echo "allready exists"
        exit;
fi 
	
## Create Database	
mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE_NAME\`"

## Create Webshop Directory
mkdir $DIRECTORY

## Download Magento
if [ "$EDITION" = "enterprise" ]; then
	composer create-project --repository-url=https://repo.magento.com/ magento/project-enterprise-edition $DIRECTORY $OPTIONS
else
	composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition $DIRECTORY $OPTIONS
fi

## Install Sample Data 
mkdir $DIRECTORY/var/composer_home

## Copy Json Auth
if [ -e auth.json ]; then
	cp $COMPOSER_AUTH_JSON_FILE_PATH $DIRECTORY/var/composer_home/auth.json
fi

## Sample Data Deploy
php $DIRECTORY/bin/magento sampledata:deploy 

## Install Magento
php $DIRECTORY/bin/magento setup:install --admin-firstname="$MAGENTO_USERNAME" --admin-lastname="$MAGENTO_USERNAME" --admin-email="$MAGENTO_USER_EMAIL" --admin-user="$MAGENTO_USERNAME" --admin-password="$MAGENTO_PASSWORD" --base-url="http://$DOMAIN" --backend-frontname="$MAGENTO_ADMIN_URL" --db-host="localhost" --db-name="$MYSQL_DATABASE_NAME" --db-user="$MYSQL_USER" --db-password="$MYSQL_PASSWORD" --language=nl_NL --currency=EUR --timezone=Europe/Amsterdam --use-rewrites=1 --session-save=files --use-sample-data 	

php $DIRECTORY/bin/magento setup:upgrade

## Developer Settings
php $DIRECTORY/bin/magento deploy:mode:set developer

mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -D magento2.$NAME -e "INSERT INTO \`core_config_data\` (\`scope\`, \`scope_id\`, \`path\`, \`value\`) VALUES ('default', 0, 'admin/security/session_lifetime', '31536000') ON DUPLICATE KEY UPDATE value='31536000';"
mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -D magento2.$NAME -e "INSERT INTO \`core_config_data\` (\`scope\`, \`scope_id\`, \`path\`, \`value\`) VALUES ('default', 0, 'web/cookie/cookie_lifetime', '31536000') ON DUPLICATE KEY UPDATE value='31536000';"
