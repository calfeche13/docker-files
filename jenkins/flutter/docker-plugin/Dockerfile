# Start from a Debian 12 (Bookworm) slim base image
FROM debian:bookworm-slim

# --- Build Arguments ---
ARG FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.2-stable.tar.xz" # Example URL for Flutter 3.29.2 stable
ARG ANDROID_CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip" # Example URL for cmdline-tools version matching 11076708
ARG JAVA_VERSION=17 # JDK version required by Android Gradle Plugin / Flutter
ARG ANDROID_PLATFORM_VERSION=36 # Target SDK Platform version for sdkmanager
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0 # Build Tools version for sdkmanager

# --- Environment Setup ---
# Set non-interactive frontend for apt-get to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
# Set locale to prevent locale errors with some tools
ENV LANG=C.UTF-8

# Define installation paths
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME

# Update PATH
ENV PATH=$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# --- Install Base Dependencies ---
# Install essential packages: Java, git, tools for downloading/extracting, Ruby for Fastlane
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    file \
    git \
    unzip \
    wget \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-${JAVA_VERSION}-jdk \
    ruby-full \
    build-essential \
 # Clean up apt cache
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Install Android SDK Command-line Tools ---
# Download using the provided URL ARG
RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
    wget -q -O cmdline-tools.zip "${ANDROID_CMDLINE_TOOLS_URL}" && \
    unzip -q cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools && \
    # The tools might unzip into a directory named 'cmdline-tools'. Rename/move it to 'latest'.
    if [ -d "$ANDROID_HOME/cmdline-tools/cmdline-tools" ]; then \
      mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest; \
    else \
      echo "Warning: Expected 'cmdline-tools' directory not found after unzip. Assuming structure is already correct or needs manual adjustment."; \
    fi && \
    rm cmdline-tools.zip

# --- Install Android SDK Components ---
# Accept licenses automatically before installing components
RUN yes | sdkmanager --licenses > /dev/null || true
# Install essential SDK components using ARG versions
RUN sdkmanager --update
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-${ANDROID_PLATFORM_VERSION}" \
    "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

# --- Install Flutter SDK ---
# Use separate steps for download and extraction for better debugging
RUN echo "Downloading Flutter SDK from ${FLUTTER_SDK_URL}..." && \
    mkdir -p ${FLUTTER_HOME} && \
    wget --progress=dot:giga -O /tmp/flutter.tar.xz "${FLUTTER_SDK_URL}"

RUN echo "Extracting Flutter SDK..." && \
    tar xf /tmp/flutter.tar.xz -C /opt/ && \
    rm /tmp/flutter.tar.xz

# --- Configure Git and Precache Flutter ---
# Add Git safe directory config to avoid dubious ownership errors when running flutter as root
RUN git config --global --add safe.directory ${FLUTTER_HOME}
# Pre-download Flutter development binaries and Android artifacts
RUN flutter precache --android --no-ios --no-web

# --- Install Fastlane ---
RUN gem install fastlane -NV --no-document

# --- Jenkins Agent Setup ---
# Create a non-root user for Jenkins agent execution
RUN groupadd -r jenkins --gid 1000 && useradd -r -g jenkins --uid 1000 -m -d /home/jenkins -s /bin/bash jenkins

# Grant ownership of SDKs to the jenkins user
RUN chown -R jenkins:jenkins $FLUTTER_HOME
RUN chown -R jenkins:jenkins $ANDROID_HOME

# --- Entrypoint Script Removed ---
# The Jenkins Docker plugin will typically provide the command to start agent.jar

# Set the default working directory (can be overridden by Jenkins config)
WORKDIR /home/jenkins

# Switch to the jenkins user
USER jenkins

# --- Entrypoint & CMD Removed ---
# Jenkins Docker plugin will specify the command to run (usually java -jar agent.jar ...)

