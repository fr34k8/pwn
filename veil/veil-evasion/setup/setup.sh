#!/bin/bash

# Print Title Function
func_title(){
  # Clear (For Prettyness)
  clear

  # Echo Title
  echo '========================================================================='
  echo ' Veil-Evasion Setup Script | [Updated]: 01.15.2015'
  echo '========================================================================='
  echo ' [Web]: https://www.veil-framework.com | [Twitter]: @VeilFramework'
  echo '========================================================================='
}

# Validation Checks Function
func_validate(){
  # Check User Permissions
  if [ `whoami` != 'root' ]
  then
    echo
    echo ' [ERROR]: Either Run This Setup Script As Root Or Use Sudo.'
    echo
    exit 1
  fi

  # install the symmetricjsonrpc pip if it isn't already there
  if [ -d /usr/local/lib/python2.7/dist-packages/symmetricjsonrpc/ ]
  then
    echo 
    echo ' [*] pip symmetricjsonrpc already installed, skipping.'
    echo
  else
    echo
    echo ' [*] Installing symmetricjsonrpc pip.'
    echo 
    yaourt -S --needed --noconfirm python-pip python2-pip
    pip2 install symmetricjsonrpc
    echo
  fi
}

# Install Wine Python Dependent Dependencies
func_python_deps(){
  # Install Wine Python and Dependencies
  # Download required files, doing no check cert because wget is having an issue with our wildcard cert
  # if you're reading this, and actually concerned you might be mitm, use a browser and just download these
  # files and then just comment these next two lines out :)
  echo
  echo ' [*] Downloading Setup Files From http://www.veil-framework.com'
  wget https://www.veil-framework.com/InstallMe/requiredfiles.zip --no-check-certificate
  wget https://www.veil-framework.com/InstallMe/pyinstaller-2.0.zip --no-check-certificate

  # Unzip Setup Files
  echo
  echo ' [*] Uncompressing Setup Archive'
  unzip requiredfiles.zip

  # Prepare Wine Directories
  echo
  echo ' [*] Preparing Wine Directories'
  mkdir -p ~/.wine/drive_c/Python27/Lib/
  cp distutils -r ~/.wine/drive_c/Python27/Lib/
  cp tcl -r ~/.wine/drive_c/Python27/
  cp Tools -r ~/.wine/drive_c/Python27/

  # Install Setup Files
  echo
  echo ' [*] Installing Wine Python Dependencies'
  wine msiexec /i python-2.7.5.msi
  wine pywin32-218.win32-py2.7.exe
  wine pycrypto-2.6.win32-py2.7.exe
  if [ -d "/usr/share/pyinstaller" ]
  then
    echo
    echo ' [*] PyInstaller Already Installed... Skipping.'
  else
    unzip -d /opt pyinstaller-2.0.zip
  fi

  # Update Veil Config
  func_update_config
}

func_update_config(){
  # run ./config/update.py
  echo
  echo ' [*] Updating Veil-Framework Configuration'
  cd ../config
  python2 update.py
}

# Menu Case Statement
    func_title
    func_python_deps
