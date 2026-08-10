FROM mcuadros/ofelia:v0.3.22

RUN apk add --no-cache \
    docker-cli \
    bash \
    tzdata

ENV TZ=Asia/Kolkata

WORKDIR /scheduler

COPY run_job.sh /scheduler/run_job.sh

RUN chmod +x /scheduler/run_job.sh