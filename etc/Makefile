all: help

sync-frontend:
	cp -f /etc/varnish/default.vcl varnish.vcl
	cp -f /etc/default/varnish varnish.default

sync-backend:
	crontab -l > crontab
	
help:
	@echo "make [ sync-backend | sync-frontend ]"
