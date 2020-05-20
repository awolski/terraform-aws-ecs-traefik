# ECS Traefik Module 

This repo contains a Module for how to deploy [Traefik](https://docs.traefik.io/) on [ECS](https://aws.amazon.com/ecs/).
 
 For small scale applications where an [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) is overkill and costly, this module provides an alternative. The module deploys [Traefik](https://docs.traefik.io/) as an ECS service complete with [Lets Encrypt](https://letsencrypt.org/) TLS certificate and a [Traefik Dashboard](https://docs.traefik.io/operations/dashboard/) Basic Auth middleware.
 
Once Traefik is running, other services will be auto-discovered if they use Traefik's [Docker Configuration Discovery](https://docs.traefik.io/providers/docker/) mechanism. See below for details.

## Features

* Creates a single auto scaled ECS container instance to host Docker containers
* Creates and associates an Elastic IP with the container instance
* Automatically creates a [Lets Encrypt](https://letsencrypt.org) TLS certificate for the provided hostname
* Uses a [security enhanced socket proxy](https://github.com/Tecnativa/docker-socket-proxy) for additional security when mounting the Docker Socket
* Enables auto discovery and routing of other ECS services launched using Traefik Configuration Discovery

## Core concepts



## Versions 

This Module follows the principles of [Semantic Versioning](http://semver.org/). You can find each new release, along with the changelog, in the [Releases Page](../../releases). 


During initial development, the major version will be 0 (e.g., `0.x.y`), which indicates the code does not yet have a stable API. Once we hit `1.0.0`, we will make every effort to maintain a backwards compatible API and use the MAJOR, MINOR, and PATCH versions on each release to indicate any incompatibilities.




