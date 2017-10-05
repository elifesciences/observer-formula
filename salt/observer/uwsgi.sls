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

app-uwsgi-upstart:
    file.managed:
        - name: /etc/init/uwsgi-observer.conf
        - source: salt://observer/config/etc-init-uwsgi-observer.conf
        - template: jinja
        - mode: 755

app-uwsgi-systemd:
    file.managed:
        - name: /lib/systemd/system/uwsgi-observer.service
        - source: salt://observer/config/lib-systemd-system-uwsgi-observer.service
        - template: jinja

app-uwsgi:
    service.running:
        - name: uwsgi-observer
        - enable: True
        - require:
            - file: uwsgi-params
            - file: app-uwsgi-upstart
            - file: app-uwsgi-systemd
            - file: app-uwsgi-conf
            - file: app-nginx-conf
            - file: log-file
        - watch:
            - install-observer
            - service: nginx-server-service
