# Jenkins Agent: Flutter Android Builder

## Overview

This repository contains the configuration for building a Docker image that functions as a Jenkins JNLP agent (also known as a node or slave). The image is specifically designed for building **Flutter applications for the Android platform**.

It comes pre-installed with the necessary versions of the Flutter SDK, Android SDK (command-line tools), Java (OpenJDK), Ruby, and Fastlane, providing a consistent environment for your CI/CD pipelines. The agent connects back to the Jenkins controller using the JNLP protocol, facilitated by the included `entrypoint.sh` script which handles downloading `agent.jar` at runtime via `wget`.

The base image used is `debian:bookworm-slim` for a balance of stability, compatibility, and reasonable size.

## Features & Included Software

*   **Base Image:** Debian 12 (Bookworm) Slim (`debian:bookworm-slim`)
*   **Java:** OpenJDK (Version configurable via build argument `JAVA_VERSION`, default: 17)
*   **Flutter SDK:** Downloaded based on the URL provided via build argument `FLUTTER_SDK_URL`. Includes `flutter precache` for Android artifacts.
*   **Android SDK:**
    *   Command-line Tools (Version based on URL provided via build argument `ANDROID_CMDLINE_TOOLS_URL`)
    *   Platform-Tools (adb, etc.)
    *   Target Android Platform (Version configurable via build argument `ANDROID_PLATFORM_VERSION`)
    *   Build-Tools (Version configurable via build argument `ANDROID_BUILD_TOOLS_VERSION`)
    *   Automatic license acceptance.
*   **Fastlane:** Latest version installed via RubyGems for automating build, test, and deployment tasks.
*   **Ruby:** `ruby-full` and `build-essential` installed as runtime dependencies for Fastlane.
*   **Git:** For checking out source code.
*   **Standard Linux Utilities:** `bash`, `curl`, `wget`, `unzip`, `xz-utils`, `zip`, `file`, `ca-certificates`.
*   **Jenkins Agent:** Runs as a dedicated non-root user (`jenkins`). Includes an `entrypoint.sh` script that handles connecting to the Jenkins controller via JNLP (runtime download of `agent.jar` is enabled by default using `wget`).

## Prerequisites

1.  **Docker:** Docker engine must be installed on the machine where you build the image and where you run the agent container.
2.  **`entrypoint.sh` Script:** The `entrypoint.sh` file (content provided separately) must be present in the same directory as the `Dockerfile` (the build context) when running `docker build`.

## Building the Docker Image

Place the `Dockerfile` and the `entrypoint.sh` script in the same directory. Navigate to that directory in your terminal and run the build command.

```bash
# Build with default versions
docker build -t your-registry/jenkins-flutter-agent:latest .

# Build specifying the platform (RECOMMENDED on Apple Silicon Macs)
docker build --platform linux/amd64 -t your-registry/jenkins-flutter-agent:latest .
```

Replace `your-registry/jenkins-flutter-agent:latest` with your desired image name and tag.

### Build-time Customization (Build Arguments)

You can customize the versions of the installed software during the build process using `--build-arg`:

| Argument                    | Default Value                                                                                | Description                                                                                   |
| --------------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `FLUTTER_SDK_URL`           | `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.2-stable.tar.xz` | **Required.** Full URL to the Flutter SDK Linux tar.xz archive.                               |
| `ANDROID_CMDLINE_TOOLS_URL` | `https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip`        | **Required.** Full URL to the Android command-line tools Linux zip archive.                 |
| `JAVA_VERSION`              | `17`                                                                                         | OpenJDK version to install (e.g., 17, 11).                                                    |
| `ANDROID_PLATFORM_VERSION`  | `36`                                                                                         | Target Android SDK Platform version to install (e.g., 34, 33).                                |
| `ANDROID_BUILD_TOOLS_VERSION`| `34.0.0`                                                                                     | Specific Android Build Tools version to install (e.g., `34.0.0`, `33.0.2`).                   |

**Example building with specific versions:**

```bash
docker build \
  --platform linux/amd64 \
  --build-arg FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz" \
  --build-arg ANDROID_CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
  --build-arg JAVA_VERSION=17 \
  --build-arg ANDROID_PLATFORM_VERSION=34 \
  --build-arg ANDROID_BUILD_TOOLS_VERSION=34.0.0 \
  -t your-registry/jenkins-flutter-agent:3.19.6 .
```

## Running the Agent Container

To run this image as a Jenkins agent, you need to provide environment variables so the `entrypoint.sh` script can connect to your Jenkins controller.

**Note:** You must configure the agent node in the Jenkins UI first (Manage Jenkins -> Nodes) to obtain the correct `JENKINS_AGENT_NAME` and `JENKINS_SECRET` (or set up the secret file).

### Runtime Configuration (Environment Variables)

The `entrypoint.sh` script uses the following environment variables when the container starts:

| Variable                      | Required?                         | Description                                                                                                                               | Example                                 |
| ----------------------------- | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| `JENKINS_URL`                 | Yes                               | Base URL of the Jenkins controller. Needed for the `-jnlpUrl` connection method and potentially for downloading `agent.jar`.              | `http://jenkins.example.com:8080`         |
| `JENKINS_AGENT_NAME`          | Yes                               | The name configured for this agent node within the Jenkins UI.                                                                            | `flutter-agent-1`                       |
| `JENKINS_SECRET`              | Yes (or `_FILE`)                  | The secret token generated by Jenkins for the JNLP agent configuration. Provide this OR the file path below.                               | `a1b2c3d4e5f6...`                       |
| `JENKINS_AGENT_SECRET_FILE` | Yes (or `JENKINS_SECRET`)         | Path inside the container to a file containing the JNLP secret. Useful for mounting secrets via Docker Secrets or volumes.                  | `/run/secrets/jenkins-agent-secret`     |
| `JENKINS_AGENT_WORKDIR`       | No                                | Optional. Path inside the container where the agent should perform checkouts and builds. Defaults to Jenkins standard behavior.             | `/home/jenkins/workspace`               |
| `JAVA_OPTS`                   | No                                | Optional. Extra options to pass to the Java Virtual Machine running the agent JAR.                                                          | `-Xmx1024m -Djava.awt.headless=true`    |
| `AGENT_JAR_PATH`              | No (Defaults to `/home/jenkins/agent/agent.jar`) | Optional. Overrides the path where the script looks for or downloads `agent.jar`. Use if mounting the JAR to a non-default location. | `/opt/jenkins/agent.jar`                |
| `AGENT_JAR_URL_SUFFIX`        | No (Defaults to `/jnlpJars/agent.jar`) | Optional. Overrides the URL path suffix used when constructing the download URL from `JENKINS_URL`.                                     | `/static/agent.jar`                     |

## Usage with `docker run`

Ensure `agent.jar` can be downloaded (via `JENKINS_URL`) OR mount `agent.jar` explicitly.

```bash
docker run -d --name flutter-agent-1 \
  -e JENKINS_URL="<Your_Jenkins_URL>" \
  -e JENKINS_AGENT_NAME="<Your_Agent_Name_From_Jenkins_UI>" \
  -e JENKINS_SECRET="<Your_Agent_Secret_From_Jenkins_UI>" \
  # Or use JENKINS_AGENT_SECRET_FILE:
  # -e JENKINS_AGENT_SECRET_FILE="/run/secrets/jenkins-agent-secret" \
  # -v /path/to/host/secret:/run/secrets/jenkins-agent-secret:ro \
  -e JENKINS_AGENT_WORKDIR="/home/jenkins/workspace" \
  -e JAVA_OPTS="-Xmx1024m" \
  # Optional: Mount caches for faster builds
  -v jenkins-gradle-cache:/home/jenkins/.gradle \
  -v jenkins-pub-cache:/home/jenkins/.pub-cache \
  # Optional: Mount agent.jar instead of relying on download
  # -v /path/to/host/agent.jar:/home/jenkins/agent/agent.jar:ro \
  your-registry/jenkins-flutter-agent:<Your_Image_Tag>
```

(Remember to create named volumes `jenkins-gradle-cache` and `jenkins-pub-cache` first using `docker volume create <volume_name>`, or use host paths for the volumes.)

## Usage with `docker-compose`

Create a `docker-compose.agent.yml` file:

```yaml
version: '3.8'

services:
  flutter-agent:
    image: your-registry/jenkins-flutter-agent:<Your_Image_Tag> # Use your built image tag
    container_name: flutter-agent-1 # Choose a name
    restart: unless-stopped
    environment:
      - JENKINS_URL=<Your_Jenkins_URL>
      - JENKINS_AGENT_NAME=<Your_Agent_Name_From_Jenkins_UI>
      # Provide secret directly:
      - JENKINS_SECRET=<Your_Agent_Secret_From_Jenkins_UI>
      # Or provide secret via file (requires secrets definition below or Docker Swarm secrets):
      # - JENKINS_AGENT_SECRET_FILE=/run/secrets/jenkins-agent-secret
      - JENKINS_AGENT_WORKDIR=/home/jenkins/workspace # Optional
      - JAVA_OPTS=-Xmx1024m # Optional
    volumes:
      # Mount caches using named volumes defined below
      - gradle_cache:/home/jenkins/.gradle
      - pub_cache:/home/jenkins/.pub-cache
      # Optional: Mount agent.jar from host
      # - ./agent.jar:/home/jenkins/agent/agent.jar:ro
      # Optional: Mount secret file from host (if not using compose 'secrets')
      # - /path/to/host/secret:/run/secrets/jenkins-agent-secret:ro
    # Optional: Define how to get the secret file (e.g., from a file on the host)
    # secrets:
    #   jenkins-agent-secret

volumes:
  gradle_cache:
  pub_cache:

# Optional: Define the source of the secret file (if using compose 'secrets')
# secrets:
#   jenkins-agent-secret:
#     file: /path/to/your/host/secret/file
```

Run using `docker-compose -f docker-compose.agent.yml up -d`.

## Volumes Explained

*   `/home/jenkins/.gradle`: Mount a volume here to persist Gradle dependencies and caches between container runs. This significantly speeds up subsequent Android builds.
*   `/home/jenkins/.pub-cache`: Mount a volume here to persist Flutter/Dart package dependencies downloaded by `pub get`. This speeds up the Flutter build process.
*   `/home/jenkins/workspace` (or path set by `JENKINS_AGENT_WORKDIR`): This is where Jenkins checks out source code and performs builds. Persisting this via a volume is optional. It's often **not recommended** for build agents to ensure a clean environment for each build, preventing potential artifacts from interfering.
*   `/home/jenkins/agent/agent.jar`: You can optionally mount the `agent.jar` file (downloaded manually from your Jenkins controller's `/jnlpJars/agent.jar` URL) to this location (read-only recommended: `:ro`). If the `entrypoint.sh` script finds the JAR at `AGENT_JAR_PATH`, it will skip the download attempt from `JENKINS_URL`.

## Customization

*   **Software Versions:** Modify the `ARG` values in the `Dockerfile` or override them during `docker build` using `--build-arg` to use different versions of Java, Flutter SDK, or Android SDK components.
*   **Additional Packages:** Add any extra packages needed for your specific build process to the `Dockerfile` using `apt-get install` for Debian packages or `gem install` for Ruby gems. Remember to run `apt-get update` before installing new packages.