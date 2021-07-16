#!/usr/bin/env bash

version="0.1.0"
repo_name="andreas-becker/sybit_proxy"
script_name="sybit_proxy.sh"

link=$(curl -L -o /dev/null -w '%{url_effective}' "https://raw.githubusercontent.com/${repo_name}/main/sybit_proxy.sh")
version=$(basename "$link")
if [ "$version" == "$script_version" ] || [ "$version" == "latest" ]; then OUTDATED="0"; else OUTDATED="1"; fi

if [ "$OUTDATED" == "1" ]; then
    printf "%s\n" "Updating script..."
    export skip="1"
    (rm "$script_name"
    curl -s "https://raw.githubusercontent.com/${repo_name}/main/sybit_proxy.sh" \
    | grep browser_download_url \
    | grep "$script_name" \
    | cut -d '"' -f 4 \
    | wget -qi -
    chmod +x "$script_name"
    clear
    eval "./${script_name}")
    exit $?
fi
