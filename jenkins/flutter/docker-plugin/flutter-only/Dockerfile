# Start from a Debian Slim base image
FROM debian:stable-slim

# --- Build Arguments ---
ARG FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz"
ARG JAVA_VERSION=17
ARG UID=1000
ARG GID=1000

# --- Environment Setup ---
# Set locale to prevent locale errors with some tools
ENV LANG=C.UTF-8

ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV PATH=$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# --- Install Base Dependencies (Debian) ---
# Install essential packages using apt
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    unzip \
    wget \
    xz-utils \
    zip \
    openjdk-${JAVA_VERSION}-jdk-headless \
    ruby \
    ruby-dev \
    build-essential \
    libstdc++6 \
    # Mesa needed for headless Flutter tests/rendering if required
    libgl1-mesa-dri \
    libglvnd0 && \
    rm -rf /var/lib/apt/lists/*

# --- Install Flutter SDK ---
# Flutter is installed *within* the image based on the ARG URL
RUN echo "Downloading Flutter SDK from ${FLUTTER_SDK_URL}..." && \
    mkdir -p ${FLUTTER_HOME} && \
    wget --progress=dot:giga -O /tmp/flutter.tar.xz "${FLUTTER_SDK_URL}"

RUN echo "Extracting Flutter SDK..." && \
    tar xf /tmp/flutter.tar.xz -C /opt/ && \
    # The archive might contain a 'flutter' directory, ensure it ends up directly in /opt/flutter
    # Adjust if the archive structure is different
    if [ -d "/opt/flutter/flutter" ]; then mv /opt/flutter/flutter/* /opt/flutter/ && rmdir /opt/flutter/flutter; fi && \
    rm /tmp/flutter.tar.xz

# --- Configure Git and Precache Flutter (without Android) ---
# Add Git safe directory config to avoid dubious ownership errors
RUN git config --global --add safe.directory ${FLUTTER_HOME}
# Pre-download Flutter development binaries
RUN flutter --disable-analytics && \
    flutter config \
    --no-enable-windows-desktop \
    --no-enable-linux-desktop \
    --no-enable-macos-desktop \
    --no-enable-web \
    --no-enable-android \
    --no-enable-ios && \
    flutter precache

# --- Install Fastlane ---
# Installs Fastlane using RubyGems
RUN gem install fastlane -NV --no-document

# --- Jenkins Agent Setup ---
# Create a non-root user 'jenkins' (adjust UID/GID if needed)
RUN addgroup --gid $GID jenkins && \
    adduser --uid $UID --home /home/jenkins --shell /bin/bash --ingroup jenkins --disabled-password jenkins

# Grant ownership of SDKs installed *in the image* to the jenkins user
# Permissions for the mounted Android SDK volume must be handled separately.
RUN chown -R jenkins:jenkins $FLUTTER_HOME

# Set the default working directory
WORKDIR /home/jenkins

# Switch to the jenkins user
USER jenkins