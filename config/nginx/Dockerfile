FROM nginx:stable
LABEL Author="Francis Ouellet fouellet@dminc.com"
RUN apt-get update \
&& apt-get install -y apache2-utils \
&& mkdir /etc/apache2 \
&& htpasswd -b -c /etc/apache2/.htpasswd kibana kibana \
&& htpasswd -b /etc/apache2/.htpasswd elasticsearch elastic \
&& htpasswd -b /etc/apache2/.htpasswd keycloak keycloak \
&& cat /etc/apache2/.htpasswd
