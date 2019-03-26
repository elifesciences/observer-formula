observer:
    app:
        secret: not-a-real-secret-key

    aws:
        # for accessing updates from event bus
        access_key_id: AKIAfdasfasdfasdfas
        secret_access_key: asdfasdfasdfasdf
        region: us-east-1

    smtp:
        host: null
        port: 587
        user: null
        pass: null


# the name of the database can be overwritten like this:
elife:
    db:
        app:
            name: observer

    # systemd/16.04+ only
    uwsgi:
        services:
            observer:
                folder: /srv/observer
