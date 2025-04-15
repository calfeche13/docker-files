#!/bin/bash
# Launches Jenkins JNLP agent using the -jnlpUrl method.
# Reads connection details, secret, workdir, JAVA_OPTS from env vars.
# Allows overriding agent.jar download URL via AGENT_JAR_DIRECT_DOWNLOAD_URL.

set -e

# --- Configuration ---
AGENT_JAR_PATH=${AGENT_JAR_PATH:-/home/jenkins/agent/agent.jar}
AGENT_JAR_URL_SUFFIX=${AGENT_JAR_URL_SUFFIX:-/jnlpJars/agent.jar}

# --- Download agent.jar if necessary ---
if [ ! -f "$AGENT_JAR_PATH" ]; then
    echo "Agent JAR not found at $AGENT_JAR_PATH. Attempting download..."
    DOWNLOAD_URL=""

    # Prioritize direct download URL if provided
    if [ -n "$AGENT_JAR_DIRECT_DOWNLOAD_URL" ]; then
        echo "Using provided AGENT_JAR_DIRECT_DOWNLOAD_URL."
        DOWNLOAD_URL="$AGENT_JAR_DIRECT_DOWNLOAD_URL"
    # Fallback to constructing URL from JENKINS_URL and suffix
    elif [ -n "$JENKINS_URL" ]; then
        echo "Constructing download URL from JENKINS_URL and AGENT_JAR_URL_SUFFIX."
        DOWNLOAD_URL="${JENKINS_URL}${AGENT_JAR_URL_SUFFIX}"
    else
        echo "Error: Cannot determine download URL. Set AGENT_JAR_DIRECT_DOWNLOAD_URL or JENKINS_URL."
        exit 1
    fi

    echo "Downloading agent.jar from ${DOWNLOAD_URL}..."
    mkdir -p "$(dirname "$AGENT_JAR_PATH")"
    # Use wget (must be installed in image) to download (-q for quiet)
    wget -q -O "$AGENT_JAR_PATH" "${DOWNLOAD_URL}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download agent.jar from ${DOWNLOAD_URL}"
        exit 1
    fi
    echo "Agent JAR downloaded successfully."
fi

# Final check to ensure agent JAR is present
if [ ! -f "$AGENT_JAR_PATH" ]; then
    echo "Error: Agent JAR is still not found at $AGENT_JAR_PATH after checks/download attempt."
    exit 1
fi

# --- Validate Required Jenkins Environment Variables ---
if [ -z "$JENKINS_URL" ]; then echo "Error: JENKINS_URL environment variable is not set."; exit 1; fi
if [ -z "$JENKINS_AGENT_NAME" ]; then echo "Error: JENKINS_AGENT_NAME environment variable is not set."; exit 1; fi

# Determine secret argument
SECRET_ARG_OPTS=()
if [ -f "$JENKINS_AGENT_SECRET_FILE" ]; then
    echo "Using secret from file: $JENKINS_AGENT_SECRET_FILE"
    SECRET_ARG_OPTS=("-secret" "@$JENKINS_AGENT_SECRET_FILE")
elif [ -n "$JENKINS_SECRET" ]; then
    echo "Using secret from JENKINS_SECRET variable."
    SECRET_ARG_OPTS=("-secret" "$JENKINS_SECRET")
else
    echo "Error: Neither JENKINS_SECRET variable nor JENKINS_AGENT_SECRET_FILE is set/found."; exit 1;
fi

# --- Optional Arguments ---
WORKDIR_ARG_OPTS=()
if [ -n "$JENKINS_AGENT_WORKDIR" ]; then
    mkdir -p "$JENKINS_AGENT_WORKDIR"
    WORKDIR_ARG_OPTS=("-workDir" "$JENKINS_AGENT_WORKDIR")
    echo "Using agent working directory: $JENKINS_AGENT_WORKDIR"
fi

# --- Launch Agent ---
# Build argument list in a bash array
JAVA_ARGS=()

# Add JAVA_OPTS from environment variable first (if set)
if [ -n "$JAVA_OPTS" ]; then
    echo "Using JAVA_OPTS: $JAVA_OPTS"
    JAVA_ARGS+=($JAVA_OPTS) # Shell performs word splitting here
fi

# Add mandatory -jar argument
JAVA_ARGS+=("-jar" "$AGENT_JAR_PATH")

# Construct and add JNLP connection arguments (default method)
JNLP_URL="${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/slave-agent.jnlp"
echo "Using JNLP connection mode: -jnlpUrl $JNLP_URL"
JAVA_ARGS+=("-jnlpUrl" "$JNLP_URL")

# Add secret arguments
if [ ${#SECRET_ARG_OPTS[@]} -gt 0 ]; then JAVA_ARGS+=("${SECRET_ARG_OPTS[@]}"); fi
# Add workdir arguments
if [ ${#WORKDIR_ARG_OPTS[@]} -gt 0 ]; then JAVA_ARGS+=("${WORKDIR_ARG_OPTS[@]}"); fi
# Add any extra arguments passed to the script itself
if [ "$#" -gt 0 ]; then JAVA_ARGS+=("$@"); fi

echo "Launching Jenkins JNLP agent..."
echo "DEBUG: Executing java with args:"
printf "  Arg: [%s]\\n" "${JAVA_ARGS[@]}" # Print args for debug

# Use exec to replace this script process with the Java process
exec java "${JAVA_ARGS[@]}"

echo "Error: Jenkins agent execution finished unexpectedly."
exit 1
