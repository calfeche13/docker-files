# Start from a base Ubuntu LTS image
FROM ubuntu:22.04

# --- Build Arguments for Versioning ---
# Define versions using ARG. These can be overridden during build time using --build-arg.
ARG FLUTTER_CHANNEL=stable
ARG FLUTTER_VERSION=3.22.2 # Specify a recent stable Flutter version
ARG JAVA_VERSION=17 # JDK version required by Android Gradle Plugin / Flutter
ARG ANDROID_CMDLINE_TOOLS_VERSION=11076708 # Check https://developer.android.com/studio#command-tools for latest version number
ARG ANDROID_PLATFORM_VERSION=34 # Target SDK Platform version
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0 # Build Tools version
ARG MIN_ANDROID_PLATFORM_VERSION=23 # Minimum SDK Platform version required by the app

# --- Environment Setup ---
# Set non-interactive frontend for apt-get to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set locale to prevent locale errors with some tools
ENV LANG C.UTF-8

# Define installation paths
ENV FLUTTER_HOME /opt/flutter
ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_SDK_ROOT $ANDROID_HOME

# Update PATH
ENV PATH $FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

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
    # Install specified Java version
    openjdk-${JAVA_VERSION}-jdk \
    # Install Ruby and build essentials for Fastlane
    ruby-full \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# --- Install Android SDK Command-line Tools ---
RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
    wget -q -O cmdline-tools.zip "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" && \
    unzip -q cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools && \
    # The tools unzip into a directory named 'cmdline-tools'. Rename/move it to 'latest'.
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm cmdline-tools.zip

# --- Install Android SDK Components ---
# Accept licenses automatically before installing components
RUN yes | sdkmanager --licenses > /dev/null || true
# Install essential SDK components using ARG versions
RUN sdkmanager --update
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-${ANDROID_PLATFORM_VERSION}" \
    "platforms;android-${MIN_ANDROID_PLATFORM_VERSION}" \
    "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"
# Optionally install other components like NDK or CMake if needed by your project
# RUN sdkmanager "ndk;..." "cmake;..."

# --- Install Flutter SDK ---
RUN mkdir -p ${FLUTTER_HOME} && \
    cd /opt && \
    wget -q -O flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" && \
    tar xf flutter.tar.xz && \
    rm flutter.tar.xz
# Pre-download Flutter development binaries
RUN flutter precache --android --no-ios --no-web

# --- Install Fastlane ---
RUN gem install fastlane -NV --no-document

# --- Jenkins Agent Setup ---
# Create a non-root user for Jenkins agent execution
RUN groupadd -r jenkins --gid 1000 && useradd -r -g jenkins --uid 1000 -m -d /home/jenkins -s /bin/bash jenkins

# Grant ownership of SDKs to the jenkins user
RUN chown -R jenkins:jenkins $FLUTTER_HOME
RUN chown -R jenkins:jenkins $ANDROID_HOME

# Copy the entrypoint script into the image (ensure entrypoint.sh is in the build context)
COPY --chown=jenkins:jenkins entrypoint.sh /home/jenkins/entrypoint.sh
RUN chmod +x /home/jenkins/entrypoint.sh

# Set the working directory for the Jenkins agent
WORKDIR /home/jenkins

# Switch to the jenkins user
USER jenkins

# Set the entrypoint script to run when the container starts
# This script will connect the agent to the Jenkins controller
ENTRYPOINT ["/home/jenkins/entrypoint.sh"]

# Default CMD can be empty or provide default args to entrypoint if needed
CMD []