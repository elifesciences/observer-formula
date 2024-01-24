{% if pillar.elife.webserver.app == "caddy" %}

app-vhost:
    file.managed:
        - name: /etc/caddy/sites.d/observer
        - template: jinja
        - source: salt://observer/config/etc-caddy-sites.d-observer
        - require:
            - caddy-config
        - require_in:
            - cmd: caddy-validate-config

{% else %}

app-vhost:
    file.managed:
        - name: /etc/nginx/sites-enabled/observer.conf
        - template: jinja
        - source: salt://observer/config/etc-nginx-sites-enabled-observer.conf
        - require:
            - pkg: nginx-server
{% if salt['elife.cfg']('cfn.outputs.DomainName') %}
            - cmd: web-ssl-enabled
{% endif %}

{% endif %}

app-uwsgi-conf:
    file.managed:
        - name: /srv/observer/uwsgi.ini
        - source: salt://observer/config/srv-observer-uwsgi.ini
        - template: jinja
        - require:
            - install-observer
            - configure-app

uwsgi-observer.socket:
    service.running:
        - enable: True

app-uwsgi:
    service.running:
        - name: uwsgi-observer
        - enable: True
        - require:
            - uwsgi-observer.socket
            - uwsgi-params
            - app-uwsgi-conf
            - app-vhost
            - log-file
            - vagrant-log-file
        - watch:
            - install-observer
            - service: nginx-server-service
