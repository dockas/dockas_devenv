version: "2"

volumes:
    mongo_vol:
    letsencrypt_vol:
    webapp_vol:

services:
    # Consul Service Discovery
    consul:
        image: consul
        network_mode: host
        ports:
            - "8300:8300"
            - "8301:8301"
            - "8400:8400"
            - "8500:8500"
            - "8600:53/udp"
            - "172.17.0.1:53:53/udp"
        environment:
            - SERVICE_8300_IGNORE=true
            - SERVICE_8301_IGNORE=true
            - SERVICE_8500_IGNORE=true
            - SERVICE_8400_IGNORE=true
            - SERVICE_8600_IGNORE=true
            - SERVICE_53_IGNORE=true
            - CONSUL_ALLOW_PRIVILEGED_PORTS=""
        command: agent -server -bootstrap -bind=0.0.0.0 -client=0.0.0.0 -advertise=192.168.99.100 -recursor=8.8.8.8 -recursor=8.8.4.4 -datacenter=dc1 -node=lero-1 -dns-port=53 -log-level debug -ui

    # Docker Registrator For Consul
    registrator:
        image: gliderlabs/registrator:latest
        depends_on:
            - consul
        volumes:
            - "/var/run/docker.sock:/tmp/docker.sock"
        command: -ip=192.168.99.100 consul://192.168.99.100:8500

    # Mongo
    mongo:
        image: mongo
        ports:
            - "27017:27017"
        volumes:
            - mongo_vol:/data
        command: --smallfiles

    # Redis
    redis:
        image: redis
        ports:
            - "6379:6379"

    # API Rest
    api_rest:
        build: ./api_rest
        ports:
            - "9000"
        volumes:
            - ./api_rest/index.js:/home/index.js
            - ./api_rest/lib:/home/lib
            - ./api_rest/config:/home/config
            - ./api_rest/Makefile:/home/Makefile
            - ./api_rest/common-config:/home/common-config
            - ./api_rest/common-logger:/home/common-logger
            - ./api_rest/common-utils:/home/common-utils
        environment:
            - SERVICE_NAME=api-rest-v1
        command: dev
        dns: ["192.168.99.100"]
        dns_search: ["consul"]

    # Webapp
    webapp:
        build: ./webapp
        volumes:
            - webapp_vol:/home/webapp/dist
            - ./webapp/src:/home/webapp/src
            - ./webapp/package.json:/home/webapp/package.json
            - ./webapp/.eslintrc.yml:/home/webapp/.eslintrc.yml
            - ./webapp/gulpfile.js:/home/webapp/gulpfile.js
            - ./webapp/gulp.config.js:/home/webapp/gulp.config.js
            - ./webapp/config:/home/webapp/config
            - ./webapp/darch:/home/webapp/darch
        depends_on:
            - api_rest
        environment:
            - SERVICE_IGNORE=true
        command: dev

    # Nginx
    nginx:
        build: ./nginx
        volumes:
            - ./nginx/servers:/home/servers
            - ./nginx/conf/nginx.conf.tmpl:/home/conf/nginx.conf.tmpl
            - ./nginx/conf/consul-template.conf:/home/conf/consul-template.conf
            - ./nginx/conf/filebeat.yml:/home/conf/filebeat.yml
            - letsencrypt_vol:/etc/letsencrypt
            - letsencrypt_vol:/var/lib/letsencrypt
            - webapp_vol:/home/webapp/dist
            - webapp_vol:/home/stage_webapp/dist
        ports:
            - "443:443"
            - "80:80"
        environment:
            - SERVICE_IGNORE=true
            - MODE=dev
        dns: ["192.168.99.100"]
        dns_search: ["consul"]