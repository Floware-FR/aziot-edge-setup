<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>


<!-- PROJECT LOGO -->
<div align="center">

# FLWR Azure Iot Setup
<br />

<img src="https://github.com/Floware-FR/flwr-vision-nano/assets/94910317/02f9ff42-eb4a-4858-a23f-dd93c8d04c33" alt="Logo" width="500" height="500">

<div>
  <a href="https://github.com/Floware-FR/flwr-vision-nano/actions/workflows/build_and_push.yml"><img src="https://github.com/Floware-FR/flwr-vision-nano/actions/workflows/build_and_push.yml/badge.svg" alt="flwr-vision-nano CI"></a>
  <a href="https://hub.docker.com/r/noebrt/flwr-nano-app"><img src="https://img.shields.io/docker/pulls/noebrt/flwr-nano-app?logo=docker" alt="Docker Pulls"></a>
    <br>
</div>
<br>


This repository contains the scripts to install azure-iot edge on Jetson or Raspberry Pi

</div>

## Introduction

First you will need to get your connection string on azure




## Raspberry

Careful you will need Debian 11 as it is the only one tested by Azure

```bash
    wget https://github.com/Floware-FR/aziot-edge-setup/releases/download/3/set-aziot-raspi.sh
    chmod +x set-aziot-raspi.sh
    sudo ./set-aziot-raspi.sh
```

## Jetson

Careful you will need Debian 11 as it is the only one tested by Azure

```bash
    wget https://github.com/Floware-FR/aziot-edge-setup/releases/download/1/setup-aziot-edge.sh
    chmod +x setup-aziot-edge.sh
    sudo ./setup-aziot-edge.sh
```


## Contributors

- **Enea de Bollivier** - Senior Edge AI engineer, Floware
- **Noé Breton** - Apprentice, Floware
- **Yassine Boussafir** - Intern, Floware

