app-nginx-conf:
    file.managed:
        - name: /etc/nginx/sites-enabled/observer.conf
        - template: jinja
        - source: salt://observer/config/etc-nginx-sites-enabled-observer.conf
        - require:
            - pkg: nginx-server
{% if salt['elife.cfg']('cfn.outputs.DomainName') %}
            - cmd: web-ssl-enabled
{% endif %}

# we used to redirect all traffic to https but don't anymore
# now we simply block all external traffic on port 80
remove-unencrypted-redirect:
    file.absent:
        - name: /etc/nginx/sites-enabled/unencrypted-redirect.conf

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
            - app-nginx-conf
            - log-file
            - vagrant-log-file
        - watch:
            - install-observer
            - service: nginx-server-service
