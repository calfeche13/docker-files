# Start from a Debian Slim base image
FROM debian:stable-slim

# --- Build Arguments ---
ARG FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/beta/linux/flutter_linux_3.32.0-0.3.pre-beta.tar.xz"
ARG JAVA_VERSION=17
ARG UID=1000
ARG GID=1000

# --- Environment Setup ---
# Set locale to prevent locale errors with some tools
ENV LANG=C.UTF-8

ENV FLUTTER_HOME=/home/jenkins/flutter
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV PATH=$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# --- Install Base Dependencies (Debian) ---
# Install essential packages using apt (as jenkins user)
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

# --- Jenkins Agent Setup (Early Creation) ---
# Create a non-root user 'jenkins' (adjust UID/GID if needed)
RUN addgroup --gid $GID jenkins && \
    adduser --uid $UID --home /home/jenkins --shell /bin/bash --ingroup jenkins --disabled-password jenkins

# Switch to the jenkins user
USER jenkins

# --- Install Flutter SDK ---
# Flutter is installed within the user's home directory
RUN echo "Downloading Flutter SDK from ${FLUTTER_SDK_URL}..." && \
    mkdir -p ${FLUTTER_HOME} && \
    wget --progress=dot:giga -O /tmp/flutter.tar.xz "${FLUTTER_SDK_URL}"

RUN echo "Extracting Flutter SDK..." && \
    tar xf /tmp/flutter.tar.xz -C /home/jenkins/ && \
    # The archive might contain a 'flutter' directory, ensure it ends up directly in /home/jenkins/flutter
    if [ -d "/home/jenkins/flutter/flutter" ]; then mv /home/jenkins/flutter/flutter/* /home/jenkins/flutter/ && rmdir /home/jenkins/flutter/flutter; fi && \
    rm /tmp/flutter.tar.xz

# --- Install Fastlane locally ---
RUN gem install --user-install fastlane -NV --no-document

# Get the Ruby version
RUN export ruby_version=$(ruby -e 'puts RUBY_VERSION.gsub(/\.\d+$/, "")')

# Add the local gem bin directory to the PATH
ENV PATH=/home/jenkins/.gem/ruby/${ruby_version}/bin:$PATH

# --- Configure Git and Precache Flutter (without Android) ---
RUN git config --global --add safe.directory ${FLUTTER_HOME}
RUN flutter --disable-analytics && \
    flutter config \
    --no-enable-windows-desktop \
    --no-enable-linux-desktop \
    --no-enable-macos-desktop \
    --no-enable-web \
    --no-enable-ios \
    --enable-android && \
    flutter precache

# Set the default working directory
WORKDIR /home/jenkins