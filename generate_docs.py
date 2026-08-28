# -*- coding: utf-8 -*-
import os, sys, json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DOCS_DIR = os.path.join(BASE_DIR, 'docs')
os.makedirs(DOCS_DIR, exist_ok=True)

def write_doc(filename, content):
    filepath = os.path.join(DOCS_DIR, filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content.strip() + '\n')
    print(f'[OK] Wrote {filename} ({len(content)} chars)')

print('generate_docs.py ready')
