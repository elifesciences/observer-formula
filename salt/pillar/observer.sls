observer:
    app:
        secret: not-a-real-secret-key

    db:
        name: observer
        username: foo
        password: bar
        host: 127.0.0.1
        port: 5432

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
