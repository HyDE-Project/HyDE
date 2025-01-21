#!/bin/bash

if ip a | grep -q "10.10."; then

    IP=$(ip -4 addr show tun0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ -n "$IP" ]; then
        echo "{\"text\": \"$IP\", \"tooltip\": \"Connected to Hack The Box\"}"
    else
        echo "{\"text\": \"No IP\", \"tooltip\": \"Failed to get IP\"}"
    fi
else
    echo "{\"text\": \"Not connected\", \"tooltip\": \"Not connected to Hack The Box\"}"
fi
