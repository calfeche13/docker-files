# Docker Files

A collection of commonly used Dockerfiles for creating specific build or development environments.

## Motivation

This repository aims to centralize and share Docker configurations that are frequently reused for various projects, streamlining the setup process for different technology stacks.

Currently, it includes configurations for:

*   **Jenkins Flutter Node:** A Dockerfile designed to set up a Jenkins agent capable of building Flutter applications.

## Want to Support Me?

If you find these Dockerfiles useful, please consider supporting me through the links below :)

<a href="https://paypal.me/ChosenAlfeche"
    target="_blank">
    <img src="https://img.shields.io/badge/PayPal-Donate-blue?style=for-the-badge&logo=paypal"
        alt="PayPal Donation" />
</a>

<a href="https://buymeacoffee.com/calfeche"
    target="_blank">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Donate-orange?style=for-the-badge&logo=buymeacoffee"
        alt="Buy Me A Coffee" />
</a>

## Usage

To use a Dockerfile from this collection:
1. Navigate into the directory of the desired configuration (e.g., `jenkins-flutter`).
2. Copy the `Dockerfile` to your own project or build context.
3. Build the Docker image using the standard `docker build` command:
   ```bash
   docker build -t <your-image-name> .
   ```

## Available Dockerfiles

*   **jenkins-flutter:** Creates a Jenkins agent node equipped with the necessary Flutter and Android SDKs for building Flutter applications. See the `jenkins-flutter/README.md` for more details. 