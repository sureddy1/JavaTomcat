FROM openjdk:8-jdk-slim-stretch

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/backports.list;\
    apt-get update;

ENV CATALINA_HOME /usr/local/apache-tomcat-9.0.21
ENV TRN_INTERNAL_DATA_DIR $CATALINA_HOME/internal_data
ENV TRN_DATA_STORAGE_DIR $CATALINA_HOME/static_data
ENV TRN_LIBREOFFICE_ONLY $LIBRE_MDOC_CONVERSIONS
ENV PATH $CATALINA_HOME/bin:$PATH:/home/tomcat/.local/bin
ENV TRN_LIBREOFFICE_BINARY libreoffice
ENV DISPLAY :5.5
ENV GALLIUM_DRIVER swr
ENV LD_LIBRARY_PATH /mesa/openswr/.local/lib:$CATALINA_HOME:$LD_LIBRARY_PATH

ENV JAVA_OPTS "$JAVA_OPTS -Djava.library.path=/usr/lib:/usr/local/apr/lib:/usr/local/apache-tomcat/9.0.21/bin:/usr/local/apache-tomcat/9.0.21/lib"

RUN apt-get -y install curl vim nano procps net-tools openssh-server tcptraceroute nscd tcpdump sudo

RUN groupadd -r tomcat && useradd -m -g tomcat tomcat;\
    echo "tomcat   ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers;

COPY apache-tomcat-9.0.21.tar.gz /usr/local/

RUN chown -R tomcat:tomcat apache-tomcat-9.0.21.tar.gz && cd /usr/local;\
    tar xvf apache-tomcat-9.0.21.tar.gz && chown -R tomcat:tomcat /usr/local/apache-tomcat-9.0.21;

RUN apt-get -y install libapr1-dev libssl-dev gcc make --no-install-recommends;\
  cd /usr/local/apache-tomcat-9.0.21/bin/ && tar xvf tomcat-native.tar.gz;\
  cd tomcat-native-1.2.21-src/native && chown -R tomcat:tomcat /usr/local/apache-tomcat-9.0.21;\
  ./configure && make && make install;\
  cd ../ rm -rf tomcat-native-1.2.21;\
  apt-get -y remove libssl-dev libapr1-dev gcc make


COPY sshd_config /etc/ssh/
COPY watchdog.sh /usr/local/apache-tomcat-9.0.21/bin/
RUN cd $CATALINA_HOME;\
    echo "root:Docker!" | chpasswd;\    
    chown -R tomcat:tomcat .;\
    chmod +x bin/watchdog.sh;
    

WORKDIR $CATALINA_HOME
USER tomcat

EXPOSE 8080

ENTRYPOINT ["/usr/local/apache-tomcat-9.0.21/bin/watchdog.sh"]
