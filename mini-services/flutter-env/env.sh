# بيئة تطوير Flutter — تُحمَّل من ~/.bashrc (أضافتها keeper.sh).
export PATH="/home/z/flutter/bin:$PATH"
# JDK كامل (javac) من Temurin إن وُجد، وإلا JRE النظام.
if [ -x /home/z/opt/jdk21/bin/javac ]; then
  export JAVA_HOME="/home/z/opt/jdk21"
elif [ -d /usr/lib/jvm/java-21-openjdk-amd64 ]; then
  export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
fi
export ANDROID_HOME="/home/z/android-sdk"
