# -*- coding: utf-8 -*-
import os, sys, json
import numpy as np

BASE_DIR = r'p:\pro\EyeXpert'
DOCS_DIR = os.path.join(BASE_DIR, 'docs')
os.makedirs(DOCS_DIR, exist_ok=True)

def write_file(filename, content):
    p = os.path.join(DOCS_DIR, filename)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(content.strip() + '\n')
    print(f'[OK] Wrote {filename} ({len(content)} chars)')

print('=== DRISHTI SIH 2026 DOCUMENTATION GENERATOR INITIALIZED ===')
