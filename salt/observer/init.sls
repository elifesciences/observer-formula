
observer-backup:
    file.managed:
        - name: /etc/ubr/observer-backup.yaml
        - source: salt://observer/config/etc-ubr-observer-backup.yaml
        - template: jinja

install-observer:
    builder.git_latest:
        - name: git@github.com:elifesciences/observer.git
        - identity: {{ pillar.elife.projects_builder.key or '' }}
        - rev: {{ salt['elife.rev']() }}
        - branch: {{ salt['elife.branch']() }}
        - target: /srv/observer/
        - force_fetch: True
        - force_checkout: True
        - force_reset: True

    file.directory:
        # observer won't be running a webserver, we're just using it for the orm
        - name: /srv/observer
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.deploy_user.username }}
        - recurse:
            - user
            - group
        - require:
            - builder: install-observer

cfg-file:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: /srv/observer/app.cfg
        - source: 
            - salt://observer/config/srv-observer-app.cfg
        - template: jinja
        - require:
            - install-observer

# observer relies on credentials in the environment for talking to AWS
aws-credentials:
    file.managed:
        - user: {{ pillar.elife.deploy_user.username }}
        - name: /home/{{ pillar.elife.deploy_user.username }}/.aws/credentials
        - source: salt://elife/templates/aws-credentials
        - defaults:
            access_id: {{ pillar.observer.aws.access_key_id }}
            secret_access_key: {{ pillar.observer.aws.secret_access_key }}
            region: {{ pillar.observer.aws.region }}
        - template: jinja
        - makedirs: True

log-file:
    file.managed:
        - name: /var/log/observer.log
        - user: {{ pillar.elife.webserver.username }}
        - group: {{ pillar.elife.webserver.username }}
        - mode: 660

vagrant-log-file:
    file.managed:
        - name: /srv/observer/observer.log
        - user: {{ pillar.elife.deploy_user.username }}
        - group: {{ pillar.elife.webserver.username }}
        - mode: 660
        - onlyif:
            - test -e /vagrant

log-file-rotation:
    file.managed:
        - name: /etc/logrotate.d/observer.conf
        - source: salt://observer/config/etc-logrotate.d-observer.conf
        - template: jinja

log-file-monitoring:
    file.managed:
        - name: /etc/syslog-ng/conf.d/observer.conf
        - source: salt://observer/config/etc-syslog-ng-conf.d-observer.conf
        - template: jinja
        - require:
            - log-file
        - watch_in:
            - service: syslog-ng

configure-app:
    cmd.run:
        - runas: {{ pillar.elife.deploy_user.username }}
        - cwd: /srv/observer/
        - name: |
            ./install.sh
            ./manage.sh collectstatic --noinput
        - require:
            - cfg-file
            - log-file
            - psql-app-db

#
# listener
#

update-listener-systemd:
    file.managed:
        - name: /lib/systemd/system/update-listener.service
        - source: salt://observer/config/lib-systemd-system-update-listener.service
        - makedirs: True
        - template: jinja
        - require:
            - configure-app

update-listener:
    {% if pillar.elife.env not in ['ci', 'end2end', 'prod', 'continuumtest'] %}
    service.dead:
    {% else %}
    service.running:
    {% endif %}
        - name: update-listener
        - enable: True
        - require:
            - file: update-listener-systemd
        - watch:
            - install-observer
            - update-listener-systemd
            - aws-credentials
