install-metabase:
    file.managed:
        - name: /srv/metabase/metabase.jar
        - makedirs: True
        - source: http://downloads.metabase.com/v0.23.1/metabase.jar
        - source_hash: md5=79c805a6c63c4d1aae5c6afe2839e667

        - watch_in:
            - service: nginx-server-service

    cmd.run:
        - name: chown -R {{ pillar.elife.deploy_user.username }} /srv/metabase/
        - require:
            - file: install-metabase

metabase-service:
    file.managed:
        - name: /etc/init/metabase.conf
        - source: salt://observer/config/etc-init-metabase.conf

    service.running:
        - name: metabase
        - watch:
            - file: install-metabase # restart if the version of metabase changes
        - require:
            - file: metabase-service

observer-backup:
    file.managed:
        - name: /etc/ubr/observer-backup.yaml
        - source: salt://observer/config/etc-ubr-observer-backup.yaml
        - template: jinja

nginx-proxy:
    file.absent:
        - name: /etc/nginx/sites-enabled/metabase.conf

#
# observer
#    

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
        - user: {{ pillar.elife.deploy_user.username }}
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

article-update-listener:
    file.managed:
        - name: /etc/init/article-update-listener.conf
        - source: salt://observer/config/etc-init-article-update-listener.conf
        - template: jinja
        - require:
            - configure-app

    service.running:
        - name: article-update-listener
        - enable: True
        - require:
            - file: article-update-listener
        - watch:
            - install-observer

