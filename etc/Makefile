all: help

sync-frontend:
	cp -f /etc/varnish/default.vcl varnish.vcl
	cp -f /etc/default/varnish varnish.default

sync-backend:
	crontab -l > crontab
	cp -f /etc/lighttpd/conf-enabled/bbbike.org.conf .
	cp -f /etc/lighttpd/lighttpd.conf .
	cp -f /etc/logrotate.d/lighttpd lighttpd.logrotate
	
help:
	@echo "make [ sync-backend | sync-frontend ]"
