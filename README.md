
Supports Java 6 and 7 and 8 either 32-bit or 64-bit version


This script will install the java archive, update the alternatives to make
the newly install java the highest priority and set alternatives to use it.

It will also configure the mozilla java plugin and either add or replace JAVA_HOME
in /etc/environment leaving a backup file called /etc/environment~ maybe making that
optional will be a future improvement.

You can obtain the latest Sun Java from: http://www.oracle.com/technetwork/java/javase/downloads/

This script is design to install only the SE JDK. Do not use it to install the JRE

Do not use this script on the RPM installer, only on the .bin or .tar.gz archives

The script needs to be run as sudo since it can't do much installing without it

There are two arguments. The first is the required and is the name of the archive being
installed. It doesn't have to be in the same directory as the install script. The second
is optional and only applies to java 6. Add 'allow' if you want to let the script install
'expect' if it isn't currently installed. Expect is required for installing java 6. It's a
tiny program that is very useful for automating tasks in bash scripts.

Examples

sudo ./oracle-java-installer.sh jdk-6u33-linux-x64.bin

sudo ./oracle-java-installer.sh /home/dude/jdk-7u5-linux-x64.tar.gz

sudo ./oracle-java-installer.sh Downloads/jdk-6u33-linux-i586.bin allow

Upgrading Java

If the script is used a system with an existing java install, then the new version of java
will be installed alongside with the new version added as the default alternative. You can 
use 'update alternatives --config java' to manually select the older version if desired. Repeat
for javac and javaws

