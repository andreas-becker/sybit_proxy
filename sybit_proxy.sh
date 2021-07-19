#!/bin/sh
###################################################################
# Script Name: sybit_proxy.sh
# Description: enable or disable the sybit proxy configuration
# Args       : enable | disable
# Author     : Andreas Becker
# Email      : asb@sybit.de
# Version    : 20210719.1
###################################################################
PROXY_HOST="192.168.1.254"
PROXY_PORT="8080"
PROXY_HTTP="http://${PROXY_HOST}:${PROXY_PORT}"

GRADLE_PROPERTIES=$HOME/.gradle/gradle.properties

enable_proxy(){
    # global
    export http_proxy="${PROXY_HTTP}"
    export HTTP_PROXY="${PROXY_HTTP}"
    export https_proxy="${PROXY_HTTP}"
    export HTTPS_proxy="${PROXY_HTTP}"
    # git
    git config --global http.proxy "${PROXY_HTTP}"
    git config --global https.proxy "${PROXY_HTTP}"
    # apt
    # echo "Sudo privileges required to write to /etc/apt/apt.conf.d/"
    apt_conf_proxy="
Acquire::http::Proxy \"$PROXY_HTTP\";
Acquire::https::Proxy \"$PROXY_HTTP\";
Acquire::ftp::Proxy \"$PROXY_HTTP\";
    "
    echo "$apt_conf_proxy" | sudo tee /etc/apt/apt.conf.d/98sybit-proxy > /dev/null
    # gradle
    TEMP_GRADLE_PROPERTIES=$( mktemp )
    egrep -v '^systemProp.https?\.proxy(Host|Port)' < $GRADLE_PROPERTIES > $TEMP_GRADLE_PROPERTIES
    gradle_proxy="systemProp.http.proxyHost=$PROXY_HOST
systemProp.http.proxyPort=$PROXY_PORT
systemProp.https.proxyHost=$PROXY_HOST
systemProp.https.proxyPort=$PROXY_PORT"
    echo "$gradle_proxy" >> $TEMP_GRADLE_PROPERTIES
    mv $TEMP_GRADLE_PROPERTIES $GRADLE_PROPERTIES
    # remove ^M from gradle file (convert previous dosfile)
    sed -i -e 's/\r$//' $GRADLE_PROPERTIES
    # maven
    if [ -f "$HOME/.m2/settings.xml.old" ]; then
        mv $HOME/.m2/settings.xml.old $HOME/.m2/settings.xml
    else
        maven_proxy="
<settings>
  <proxies>
   <proxy>
      <active>true</active>
      <protocol>http</protocol>
      <host>$PROXY_HOST</host>
      <port>$PROXY_PORT</port>
    </proxy>
  </proxies>
</settings>
        "
        echo "$maven_proxy" | tee $HOME/.m2/settings.xml > /dev/null
    fi
    # curl
    if [ -f "$HOME/.curlrc.old" ]; then
        mv $HOME/.curlrc.old $HOME/.curlrc
    else
        curl_proxy="proxy = ${PROXY_HTTP}"
        echo "$curl_proxy" | tee $HOME/.curlrc > /dev/null
    fi
    # npm
    npm config set proxy "${PROXY_HTTP}"
    # wget
    if [ -f "$HOME/.wgetrc.old" ]; then
        mv $HOME/.wgetrc.old $HOME/.wgetrc
    else
        wget_proxy="
http_proxy = ${PROXY_HTTP}
https_proxy = ${PROXY_HTTP}
use_proxy = on
        "
        echo "$wget_proxy" | tee $HOME/.wgetrc > /dev/null
    fi
}

disable_proxy(){
    # global
    unset http_proxy
    unset HTTP_PROXY
    unset https_proxy
    unset HTTPS_PROXY
    # git
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    # apt
    if [ -f "/etc/apt/apt.conf.d/98sybit-proxy" ]; then
        # echo "Sudo privileges required to remove from /etc/apt/apt.conf.d/"
        sudo rm -f /etc/apt/apt.conf.d/98sybit-proxy
    fi
    # gradle
    TEMP_GRADLE_PROPERTIES=$( mktemp )
    egrep -v '^systemProp.https?\.proxy(Host|Port)' < $GRADLE_PROPERTIES > $TEMP_GRADLE_PROPERTIES
    gradle_proxy="systemProp.http.proxyHost=
systemProp.http.proxyPort=
systemProp.https.proxyHost=
systemProp.https.proxyPort="
    echo "$gradle_proxy" >> $TEMP_GRADLE_PROPERTIES
    mv $TEMP_GRADLE_PROPERTIES $GRADLE_PROPERTIES
    # remove ^M from gradle file (convert previous dosfile)
    sed -i -e 's/\r$//' $GRADLE_PROPERTIES
    # maven
    if [ -f "$HOME/.m2/settings.xml" ]; then
        mv $HOME/.m2/settings.xml $HOME/.m2/settings.xml.old
    fi
    # curl
    if [ -f "$HOME/.curlrc" ]; then
        mv $HOME/.curlrc $HOME/.curlrc.old
    fi
    # npm
    npm config delete proxy
    # wget
    if [ -f "$HOME/.wgetrc" ]; then
        mv $HOME/.wgetrc $HOME/.wgetrc.old
    fi
}

show_setting(){
    echo "Current proxy:" $https_proxy
}

if [ "$1" = "enable" ]
then
    enable_proxy

elif [ "$1" = "disable" ]
then
    disable_proxy

else
    show_setting
fi
