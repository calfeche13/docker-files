# Jenkins Agent Image for Docker Plugin (Flutter/Android)

## Overview

This Dockerfile creates a Docker image specifically designed to be used with the [Jenkins Docker Plugin](https://plugins.jenkins.io/docker-plugin/). It provides a Jenkins agent environment pre-configured with the necessary tools for building Flutter applications for the Android platform.

Unlike standalone JNLP agents that might use a custom entrypoint script, this image is built with the expectation that the Jenkins Docker Plugin will dynamically provision containers based on this image and manage the agent startup process within the container.

**Base Image:** `debian:bookworm-slim`

## How it Works with Jenkins Docker Plugin

The Jenkins Docker Plugin allows Jenkins to start Docker containers dynamically to act as Jenkins agents. When a build requires an agent with specific capabilities (defined by labels), Jenkins can be configured to:

1.  Start a new container using an image built from this `Dockerfile`.
2.  Connect to the container and launch the Jenkins agent process (e.g., `agent.jar`) inside it. Common connection methods configured in the plugin are "Connect with JNLP" or "Attach Docker container".
3.  Run the build within the container.
4.  Stop and potentially remove the container once the build is complete.

This `Dockerfile` facilitates this by:

*   Installing necessary dependencies, including a Java runtime (required by `agent.jar`).
*   Setting up a dedicated `jenkins` user (`uid=1000`) for running the agent process.
*   **Intentionally omitting** an `ENTRYPOINT` or `CMD`. The Docker plugin provides the necessary command to start the agent (e.g., `java <options> -jar agent.jar ...`) based on the chosen connection method.
*   Setting a default `WORKDIR` (`/home/jenkins`).

Refer to the [Jenkins Docker Plugin documentation](https://plugins.jenkins.io/docker-plugin/) for detailed information on connection methods and configuration.

## Included Software

*   **Base Image:** Debian 12 (Bookworm) Slim (`debian:bookworm-slim`)
*   **Java:** OpenJDK (Version configurable via build argument `JAVA_VERSION`, default: 17)
*   **Flutter SDK:** Downloaded based on the URL provided via build argument `FLUTTER_SDK_URL`. Includes `flutter precache` for Android artifacts.
*   **Android SDK:**
    *   Command-line Tools (Version based on URL provided via build argument `ANDROID_CMDLINE_TOOLS_URL`)
    *   Platform-Tools (adb, etc.)
    *   Target Android Platform (Version configurable via build argument `ANDROID_PLATFORM_VERSION`)
    *   Build-Tools (Version configurable via build argument `ANDROID_BUILD_TOOLS_VERSION`)
    *   Automatic license acceptance.
*   **Fastlane:** Latest version installed via RubyGems.
*   **Ruby:** `ruby-full` and `build-essential`.
*   **Git:** For checking out source code.
*   **Standard Linux Utilities:** `bash`, `curl`, `wget`, `unzip`, `xz-utils`, `zip`, `file`, `ca-certificates`, `libglu1-mesa`.
*   **Jenkins User:** A non-root user `jenkins` (uid 1000, gid 1000) is created, and ownership of SDKs is granted to this user.

## Build Arguments

You can customize the versions of the installed software during the build process using `--build-arg`:

| Argument                    | Default Value                                                                                | Description                                                                                   |
| --------------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `FLUTTER_SDK_URL`           | `https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.2-stable.tar.xz` | **Required.** Full URL to the Flutter SDK Linux tar.xz archive.                               |
| `ANDROID_CMDLINE_TOOLS_URL` | `https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip`        | **Required.** Full URL to the Android command-line tools Linux zip archive.                 |
| `JAVA_VERSION`              | `17`                                                                                         | OpenJDK version to install (e.g., 17, 11).                                                    |
| `ANDROID_PLATFORM_VERSION`  | `36`                                                                                         | Target Android SDK Platform version to install (e.g., 34, 33).                                |
| `ANDROID_BUILD_TOOLS_VERSION`| `34.0.0`                                                                                     | Specific Android Build Tools version to install (e.g., `34.0.0`, `33.0.2`).                   |

## Building the Docker Image

Navigate to the directory containing this `Dockerfile` and run the build command. Tag the image with a name that you will use in the Jenkins configuration.

```bash
# Build with default versions
docker build -t your-registry/jenkins-flutter-dynamic-agent:latest .

# Build specifying the platform (RECOMMENDED on Apple Silicon Macs)
docker build --platform linux/amd64 -t your-registry/jenkins-flutter-dynamic-agent:latest .

# Build with specific versions using build arguments
docker build \
  --platform linux/amd64 \
  --build-arg FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.6-stable.tar.xz" \
  --build-arg ANDROID_CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
  --build-arg JAVA_VERSION=17 \
  --build-arg ANDROID_PLATFORM_VERSION=34 \
  --build-arg ANDROID_BUILD_TOOLS_VERSION=34.0.0 \
  -t your-registry/jenkins-flutter-dynamic-agent:3.19.6 .
```

Replace `your-registry/jenkins-flutter-dynamic-agent` with your desired image repository and name.

## Configuring in Jenkins (Docker Plugin)

1.  **Install Plugin:** Ensure the [Docker Plugin](https://plugins.jenkins.io/docker-plugin/) is installed in Jenkins.
2.  **Configure Cloud:**
    *   Go to `Manage Jenkins` -> `System Configuration` -> `Clouds`.
    *   Add a new cloud of type `Docker`.
    *   Configure the `Docker Host URI` (e.g., `unix:///var/run/docker.sock` if Docker is on the same host as Jenkins, or `tcp://docker-host:2375` for a remote Docker daemon).
    *   Test the connection.
3.  **Add Agent Template:**
    *   Within the Docker Cloud configuration, click `Docker Agent templates...` -> `Add Docker Template`.
    *   **Labels:** Assign one or more labels (e.g., `flutter-android docker dynamic`) that your Jenkins jobs will use to request an agent based on this template.
    *   **Name:** Give the template a descriptive name (e.g., `flutter-android-dynamic`).
    *   **Docker Image:** Enter the name and tag of the image you built (e.g., `your-registry/jenkins-flutter-dynamic-agent:latest`).
    *   **Remote File System Root:** Specify the container's working directory for the agent. Using `/home/jenkins/agent` is common (a subdirectory within the user's home).
    *   **Connect method:** Choose how Jenkins connects to start the agent inside the container. Common options are:
        *   `Connect with JNLP`: The container connects back to Jenkins. Requires the Jenkins URL to be reachable from the container.
        *   `Attach Docker container`: Jenkins attaches to the started container to launch the agent. Simpler network setup if Jenkins and Docker are on the same host.
    *   **User:** Specify `jenkins` or the UID `1000`. This ensures processes inside the container run as the non-root user created in the Dockerfile.
    *   **Pull strategy:** Select `Never pull` if the image was built locally and is available on the Docker host Jenkins connects to, but not in a remote registry. Otherwise, choose an appropriate pull strategy (`Pull always`, `Pull if not found`).
    *   Adjust other settings like Memory/CPU limits as needed.

## Usage in Jenkins Jobs

In your Jenkins Pipeline script or job configuration, use the label(s) you defined in the Docker Agent Template:

```groovy
pipeline {
    agent {
        label 'flutter-android && docker' // Example using labels
    }
    stages {
        stage('Build') {
            steps {
                sh 'flutter doctor'
                sh 'flutter build apk --release'
                // ... other build steps
            }
        }
    }
}
```

## Volumes (Caching)

To speed up builds by persisting dependencies, you can configure volume mounts within the Jenkins Docker Agent Template settings:

*   **Gradle Cache:** Mount a volume to `/home/jenkins/.gradle`. This persists Gradle dependencies.
*   **Pub Cache:** Mount a volume to `/home/jenkins/.pub-cache`. This persists Flutter/Dart package dependencies.

Example (in Jenkins Agent Template -> Volumes):

*   `/path/on/host/or/named/volume/gradle:/home/jenkins/.gradle`
*   `/path/on/host/or/named/volume/pub:/home/jenkins/.pub-cache`

Using named Docker volumes is generally recommended over host paths.