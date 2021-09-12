Test Rig Info
--------------

System: Raspberry Pi 4, 8GB, 32GB Mem
OS: Official Raspberry Pi OS (32 BIT) from Raspberry Pi Imager

```bash
  `.::///+:/-.        --///+//-:``
 `+oooooooooooo:   `+oooooooooooo:
  /oooo++//ooooo:  ooooo+//+ooooo.
  `+ooooooo:-:oo-  +o+::/ooooooo:
   `:oooooooo+``    `.oooooooo+-
     `:++ooo/.        :+ooo+/.`       pi
        ...`  `.----.` ``..           ------------------- 
     .::::-``:::::::::.`-:::-`        OS: Raspbian GNU/Linux 10 (buster) armv7l 
    -:::-`   .:::::::-`  `-:::-       Host: Raspberry Pi 4 Model B Rev 1.4 
   `::.  `.--.`  `` `.---.``.::`      Kernel: 5.10.17-v7l+ 
       .::::::::`  -::::::::` `       Uptime: 27 days, 10 hours, 58 mins 
 .::` .:::::::::- `::::::::::``::.    Packages: 2066 (dpkg) 
-:::` ::::::::::.  ::::::::::.`:::-   Shell: bash 5.0.3 
::::  -::::::::.   `-::::::::  ::::   CPU: BCM2711 (4) @ 1.500GHz 
-::-   .-:::-.``....``.-::-.   -::-   Memory: 1350MiB / 7875MiB 
 .. ``       .::::::::.     `..`..
   -:::-`   -::::::::::`  .:::::`                             
   :::::::` -::::::::::` :::::::.
   .:::::::  -::::::::. ::::::::
    `-:::::`   ..--.`   ::::::.
      `...`  `...--..`  `...`
            .::::::::::
             `.-::::-`
```

DEV:
-----

Init:
1. I have cloned the repository and duplicated the Dockerfile as Dockerfile.arm for testing.
2. I used already existing ruby [arch (arm32v7l)] docker image from the Dockerhub
https://hub.docker.com/r/arm32v7/ruby/ as base image.
3. As the base image which is ruby:2.6 supports all architecture. I wanted to make sure we can do as little as changes possible if we can integrate all the platforms.

New Image DEV:
------------------
1. The libmariadbclient-dev was the first one that needed to be resolved, changed to use packages from Debian security.
2. During install of libmariadbclient-dev needed to install its dependency of libmariadbclient18 (THIS CAN BE IMPROVED)
3. setcap command was not found in the base image, hence installed libcap2-bin for setcap
4. There was a user permission issue on Gemfile.lock so copied with the postal user as permission in Dockerfile.
5. I got an image in the Docker registry for arm32v7l [NOT WORKING YET].

Docker image
```
docker pull armourshield/postal:latest-arm
```

Current Status:
-------
Getting few errors while initializing, not familiar with ruby env's so will figure this out and continue to see what I can do

```bash
postal initialize
```

![image](https://user-images.githubusercontent.com/42208036/132139707-be0eb735-2536-40e6-bc70-5c45e5f22609.png)

If anyone knows what I can do here, please do share :). Many thinks will continue to work on this.
---

Building docker image command

The docker image is built using buildx on arm32v7 arch for now as base testing.

```bash
docker buildx build --platform linux/arm/v7 -t armourshield/postal:latest-arm -f Dock
erfile.arm . --push
```