#!/bin/bash

echo "Checking DevOps tools..."
echo "------------------------"

for tool in git docker ansible-playbook aws java; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "[OK] $tool is installed"
    else
        echo "[MISSING] $tool is not installed"
    fi
done

echo "------------------------"
echo "Environment check complete."
