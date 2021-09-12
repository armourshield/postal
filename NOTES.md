# Building ruby image for linux/arm/v7

Scenario 1:
Directly building the image using moby/buildx tools for arm platforms. See how many steps fails and report here.

I am attempting to build the image for following platform
linux/arm/v7

1. Error found on 3/13 during Dockerfile build.

```Dockerfile
RUN apt-get update &&   apt-get install -y --no-install-recommends   build-essential    netcat   curl   libmariadbclient-dev   nano   
nodejs
```

Error is on libmariadbclient-dev

Solution provided by docker buildx

```bash
#8 34.48 However the following packages replace it:
#8 34.48   mariadb-server-10.1:i386 mariadb-server-10.1:ppc64el
#8 34.48   mariadb-server-10.1:amd64 libmariadb-dev-compat libmariadb-dev  
#8 34.48
#8 34.87 E: Package 'libmariadbclient-dev' has no installation candidate
```

This error might be caused due to apt repo which is amd64 repository

client from libmariadbclient18 libmariadbclient-dev libcap2-bin (setcap)

---

Building docker image command

The docker image is built using buildx on arm32v7 arch for now as base testing.

```bash
docker buildx build --platform linux/arm/v7 -t armourshield/postal:latest-arm -f Dock
erfile.arm . --push
```