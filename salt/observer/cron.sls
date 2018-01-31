daily-metrics-import:
    cron.present:
        - user: {{ pillar.elife.deploy_user.username }}
        - identifier: daily-metrics-import
        - name: cd /srv/observer/ && ./manage.sh load_from_api --target elife-metrics
        - special: '@daily'
