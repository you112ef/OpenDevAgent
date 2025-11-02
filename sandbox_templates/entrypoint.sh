#!/bin/bash
set -e

cd /sandbox

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
fi

if [ -f "tests.py" ]; then
    python -m pytest tests.py -v
elif [ -f "main.py" ]; then
    python main.py
else
    echo "No executable files found"
    ls -la
fi
