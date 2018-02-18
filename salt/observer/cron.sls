daily-metrics-import:
    cron.present:
        - user: {{ pillar.elife.deploy_user.username }}
        - identifier: daily-metrics-import
        - name: cd /srv/observer/ && ./daily.sh
        - special: '@daily'
