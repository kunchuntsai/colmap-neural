#!/usr/bin/env python3
# scripts/download_models.py

import os
import sys
import urllib.request
import hashlib
from pathlib import Path
import shutil
import tarfile
import zipfile

def main():
    print("Downloading pre-trained neural network models...")
    
    # Get the project root directory
    script_dir = Path(__file__).parent.absolute()
    project_root = script_dir.parent
    models_dir = project_root / "models"
    
    # Create models directory if it doesn't exist
    models_dir.mkdir(exist_ok=True)
    
    # Define models to download
    models = [
        {
            "name": "SuperPoint",
            "url": "https://github.com/magicleap/SuperPointPretrainedNetwork/raw/master/superpoint_v1.pth",
            "filename": "superpoint_v1.pth",
            "md5": "9420757b5e4c39114784df7f8aede33d"
        },
        {
            "name": "SuperGlue",
            "url": "https://github.com/magicleap/SuperGluePretrainedNetwork/raw/master/models/weights/superglue_outdoor.pth",
            "filename": "superglue_outdoor.pth",
            "md5": "9806a1fafbb782b1fd41824f9702f446"
        },
        {
            "name": "NetVLAD",
            "url": "https://www.dropbox.com/s/eu6d876pq63ln1f/pittsburgh_trained.zip",
            "filename": "netvlad_pittsburgh.zip",
            "md5": "89a2243b654e9c0da4b8b382b69268e3",
            "is_archive": True
        },
        {
            "name": "MVSNet",
            "url": "https://drive.google.com/uc?export=download&id=1cZ_-vZwUYj1mL8EPqcehxDQK_YmMAS7o", 
            "filename": "mvsnet_weights.tar.gz",
            "md5": "07659ec80b49e0734777e36161fa1ff8",
            "is_archive": True
        }
    ]
    
    # Download each model
    for model in models:
        model_path = models_dir / model["filename"]
        
        print(f"Downloading {model['name']}...")
        
        if model_path.exists():
            # Verify existing file with MD5
            md5 = hashlib.md5(open(model_path, 'rb').read()).hexdigest()
            if md5 == model["md5"]:
                print(f"  ✅ {model['name']} already downloaded and verified.")
                if model.get("is_archive", False) and not (models_dir / model["name"].lower()).exists():
                    extract_archive(model_path, models_dir / model["name"].lower())
                continue
            else:
                print(f"  ⚠️ {model['name']} exists but MD5 checksum doesn't match. Re-downloading...")
        
        # Download the file
        try:
            urllib.request.urlretrieve(model["url"], model_path)
            
            # Verify downloaded file
            md5 = hashlib.md5(open(model_path, 'rb').read()).hexdigest()
            if md5 != model["md5"]:
                print(f"  ❌ Downloaded {model['name']} MD5 checksum doesn't match!")
                continue
                
            print(f"  ✅ {model['name']} downloaded and verified successfully.")
            
            # Extract if it's an archive
            if model.get("is_archive", False):
                extract_archive(model_path, models_dir / model["name"].lower())
                
        except Exception as e:
            print(f"  ❌ Failed to download {model['name']}: {e}")

def extract_archive(archive_path, extract_dir):
    print(f"  📦 Extracting {archive_path.name} to {extract_dir}")
    
    # Create extraction directory
    extract_dir.mkdir(exist_ok=True)
    
    # E