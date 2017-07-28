#!/bin/bash

envFile=".env"

if [ -f "$envFile" ]
then
  . $envFile

  sed -i "/server.domain=/ s/=.*/=$SERVER_DOMAIN/" ./server/src/main/resources/config.properties
  sed -i "/jdbc.database=/ s/=.*/=$POSTGRES_DB/" ./server/src/main/resources/config.properties
  sed -i "/jdbc.username=/ s/=.*/=$POSTGRES_USER/" ./server/src/main/resources/config.properties
  sed -i "/jdbc.password=/ s/=.*/=$POSTGRES_PASSWORD/" ./server/src/main/resources/config.properties
  sed -i "/recaptcha.secret=/ s/=.*/=$RECAPTCHA_SERVER/" ./server/src/main/resources/config.properties


  sed -i "/var reCaptcha=/ s/=.*/=\"$RECAPTCHA_CLIENT\";/" ./static-page/src/js/actionLogin.js

  pushd static-page
  gradle build
  popd

  pushd server
  gradle shadowJar
  popd

  # prepare artifacts to deploy
  images=(static-apache static-nginx server postgres)
  for i in "${images[@]}"; do
    rm -R ./devops/$i/dist
    mkdir ./devops/$i/dist
  done

  cp -R ./static-page/papka/* ./devops/static-apache/dist
  cp -R ./static-page/papka/* ./devops/static-nginx/dist
  cp ./server/build/libs/papka-24.jar ./devops/server/dist
  cp ./server/build/resources/main/sql/CreateDB.sql ./devops/postgres/dist

  sudo docker-compose up $1

else
  echo "'$envFile' not found."
  echo "copy '.env.template' to '$envFile' and update it according to your environment"
fi

