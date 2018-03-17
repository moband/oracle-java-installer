#!/bin/bash

RETURN_VALUE=0
 
get-priority() {
  local priority=100   
  local command_name=$1
  while read line
  do
    if [[ $line =~ .*priority.([0-9]+)$ ]]; then
      echo $line
      local value=${BASH_REMATCH[1]}
      if [ ${value} -gt ${priority} ]; then
        priority=${value}
      fi
    fi
  done < <(update-alternatives --display ${command_name})
  let RETURN_VALUE=${priority}+1
}
                                                     
if [ "$(id -u)" != "0" ]; then
  echo "Please run as Superuser"
  exit 1
fi
 
if [ $# -lt 1 ]; then
  echo "usage: install-sun-java.sh <java installer archive or bin> <'allow' to let script install expect>"
  exit 1 
fi
 
full_archive_name=$1
 
allow_apt_get=$2
 
if [ ! -f $full_archive_name ]; then
  echo "FATAL ERROR: File $full_archive_name not found"
  exit 1
fi
 
# Parse archive name
archive_path=$(dirname ${full_archive_name})
archive_file=$(basename ${full_archive_name})
 
if [[ $archive_file =~ ^jdk-([6-8]+)u([0-9]+)-linux-(i586|x64).* ]]; then
   major_version=${BASH_REMATCH[1]}
   update=$(printf "%02d" ${BASH_REMATCH[2]})  
   arch=${BASH_REMATCH[3]}
else
  echo "FATAL ERROR: $archive_file is not recognized as a java installer"
  exit 1
fi
 
jdk_version="1.${major_version}.0_${update}"
 
echo "Installing Java Using JDK ${jdk_version}"
 
# Extract Files
 
echo "# Changing Directory"
cd ${archive_path}
echo $(pwd)
echo "#  Extracting Archive ${archive_file}"
if [ $major_version -eq "8" ]; then
  tar -zxvf ${archive_file}
else
  if [[ ! $(which expect) =~ .*expect.* ]]; then
    if [ "${allow_apt_get}" = "allow" ]; then
      apt-get -y install expect
    else
      echo "The program 'expect' is required to run the script."
      echo "You can run the script again and add the argument 'allow' to have the script automatically install it for you."
      echo "example: sudo ./install-oracle-java.sh jdk-6u33-linux-x64.bin allow"
      exit 1
    fi
  fi
  chmod +x ${archive_file}
  expect <<EOD
    set timeout 300      
    spawn ./${archive_file}
    expect "Press Enter"
    send "\r"
    interact
EOD
fi
 
jdk_dir="jdk${jdk_version}"
 
# Confirm the directory
 
if [ ! -d $jdk_dir ]; then
  echo "FATAL ERROR: Can't find extracted directory"
  exit 1
fi
 
echo "# Move into jvm library..."
 
# Move Directory to jvm library
mkdir -p /usr/lib/jvm
mv -v ${jdk_dir} /usr/lib/jvm
 
# Set alternatives
echo "# Update Javac Alteratives..."
echo "# Don't worry if you see an error here - it just means there are no other versions of java installed"
get-priority "javac"
javac_priority=$RETURN_VALUE
update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/${jdk_dir}/bin/javac ${javac_priority}
update-alternatives --auto javac
 
echo "# Update Java Alteratives..."
echo "# Don't worry if you see an error here - it just means there are no other versions of java installed"
get-priority "java"
java_priority=$RETURN_VALUE
update-alternatives --install /usr/bin/java java /usr/lib/jvm/${jdk_dir}/bin/java ${java_priority}
update-alternatives --auto java
 
echo "# Update Javaws Alteratives..."
echo "# Don't worry if you see an error here - it just means there are no other versions of java installed"
get-priority "javaws"
javaws_priority=$RETURN_VALUE
update-alternatives --install /usr/bin/javaws javaws /usr/lib/jvm/${jdk_dir}/bin/javaws ${javaws_priority}
update-alternatives --auto javaws
 
# Enable Java Plug for Mozilla
echo "# Enable Mozilla Java Plug-in..."
if [ -d /usr/lib/mozilla/plugins ]; then
  if [ $arch == "x64" ]; then
    ln -sf /usr/lib/jvm/${jdk_dir}/jre/lib/amd64/libnpjp2.so /usr/lib/mozilla/plugins 
  else
    ln -sf /usr/lib/jvm/${jdk_dir}/jre/lib/i386/libnpjp2.so /usr/lib/mozilla/plugins
  fi
else
  echo "# Mozilla not detected, skipping..."
fi
 
if [[ $(grep 'JAVA_HOME' /etc/environment) =~ ^JAVA_HOME ]]; then
  cp /etc/environment /etc/environment~
  sed "s@^JAVA_HOME=.*@JAVA_HOME=/usr/lib/jvm/${jdk_dir}@" < /etc/environment~ > /etc/environment
else
  echo "JAVA_HOME=/usr/lib/jvm/${jdk_dir}" >> /etc/environment
fi
 
# Ending Notes
echo "# Java is Installed..."
echo "# Use the command 'export JAVA_HOME=/usr/lib/jvm/${jdk_dir}' to use java right now."
echo "# The environment varible should be set system wide on restart."
 
# End by showing version
echo "# Show Version..."
java -version
 
exit 0
