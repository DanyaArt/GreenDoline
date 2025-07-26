#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

# Import Flask app
from bot import app

# AlwaysData specific configuration
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
