# Jenkins Flutter Node Dockerfile

This Dockerfile sets up a Jenkins agent environment capable of building Flutter applications, including the necessary Flutter and Android SDK installations.

## Usage

1.  **Copy the Dockerfile:** Place this `Dockerfile` in the root of the project you intend to build, or in a dedicated directory for your Jenkins agent image.

2.  **Build the Image:** Use the Docker command line to build the image. Replace `<your-image-name>` with a suitable tag (e.g., `jenkins-agent/flutter-android`):

    ```bash
    docker build -t <your-image-name> .
    ```

3.  **Configure Jenkins:**
    *   Add a new Jenkins agent configuration.
    *   Configure it to use the Docker image you just built.
    *   Ensure your Jenkins pipeline steps execute within this agent environment.

## Included Software

*   Ubuntu (Base Image)
*   Java (Required by Jenkins agent and Android SDK tools)
*   Flutter SDK
*   Android SDK (including command-line tools, build-tools, platform-tools, and necessary platforms)
*   Necessary dependencies for Flutter and Android development. 