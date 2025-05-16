FROM ubuntu:20.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Set up timezone (required for some package installations)
RUN apt-get update && apt-get install -y tzdata
ENV TZ=Etc/UTC

# Install basic tools and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    vim \
    locales \
    build-essential \
    file \
    apt-utils \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install OpenJDK 14 (as required by the project - newer versions cause crashes)
# Download and install manually since it's not available in standard repos
RUN apt-get update && apt-get install -y software-properties-common \
    && mkdir -p /opt/java \
    && cd /opt/java \
    && wget -q https://download.java.net/java/GA/jdk14.0.2/205943a0976c4ed48cb16f1043c5c647/12/GPL/openjdk-14.0.2_linux-x64_bin.tar.gz \
    && tar -xzf openjdk-14.0.2_linux-x64_bin.tar.gz \
    && rm openjdk-14.0.2_linux-x64_bin.tar.gz

# Set JAVA_HOME and update PATH
ENV JAVA_HOME=/opt/java/jdk-14.0.2
ENV PATH=$JAVA_HOME/bin:$PATH

# Verify Java version
RUN java -version

# Install Android SDK
ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools/
WORKDIR ${ANDROID_HOME}/cmdline-tools/

# Download and install Android command line tools
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-6858069_latest.zip -O android-sdk.zip \
    && unzip -q android-sdk.zip \
    && mv cmdline-tools latest \
    && rm android-sdk.zip \
    && mkdir -p ${ANDROID_HOME}/licenses/

# Accept all Android SDK licenses
RUN echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > ${ANDROID_HOME}/licenses/android-sdk-license \
    && echo "84831b9409646a918e30573bab4c9c91346d8abd" > ${ANDROID_HOME}/licenses/android-sdk-preview-license

# Install Android SDK components
RUN yes | sdkmanager --install "platform-tools" \
    "platforms;android-30" \
    "platforms;android-29" \
    "platforms;android-28" \
    "build-tools;30.0.3" \
    "build-tools;29.0.3" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services"

# Install Gradle
ENV GRADLE_VERSION 7.1.1
ENV GRADLE_HOME /opt/gradle-${GRADLE_VERSION}
ENV PATH ${PATH}:${GRADLE_HOME}/bin

RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -O gradle.zip \
    && unzip -q gradle.zip -d /opt \
    && rm gradle.zip

# Set up working directory
WORKDIR /app

# Install Gradle directly instead of using wrapper
RUN mkdir -p /app/gradle/wrapper/
RUN echo "distributionUrl=https\://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" > /app/gradle/wrapper/gradle-wrapper.properties
RUN echo "distributionBase=GRADLE_USER_HOME" >> /app/gradle/wrapper/gradle-wrapper.properties
RUN echo "zipStoreBase=GRADLE_USER_HOME" >> /app/gradle/wrapper/gradle-wrapper.properties
RUN echo "zipStorePath=wrapper/dists" >> /app/gradle/wrapper/gradle-wrapper.properties
RUN echo "distributionPath=wrapper/dists" >> /app/gradle/wrapper/gradle-wrapper.properties

# Entry point script
RUN echo '#!/bin/bash\nset -e\nexec "$@"' > /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]