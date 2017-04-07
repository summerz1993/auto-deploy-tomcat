#define env
export JAVA_HOME=/root/installer/jdk/jdk1.8.0_91
export MAVEN_HOME="/root/maven/apache-maven-3.3.9"
export GIT_URL="git@git.oschina.net:summerzhang/pure-operation.git"
export GIT_REPO="/root/test-git/pure/"
export APP_NAME="pure-operation"
export TOMCAT_HOME="/root/server/test/apache-tomcat-7.0.70/"
export TEST_URL="http://120.26.241.165:8889/pure-operation"
export KILL_TOMCAT_KEYWORD="test"
export AUTODEPLOY_LOG_HOME="/root/log/tomcat" || check_dir $AUTODEPLOY_LOG_HOME
export AUTODEPLOY_LOG_FILE="$AUTODEPLOY_LOG_HOME/auto_deploy.log"

#git pull
function update_code(){
	cd $GIT_REPO
	git pull $GIT_URL master
	git status
	[ $? -eq 0 ] || echo "git pull failed"
	log_file "GIT updateCode is completed ------------>"
}

#package
function package(){
	cd $GIT_REPO
	$MAVEN_HOME/bin/mvn clean compile package -Dmaven.test.skip=true
	[ $? -eq 0 ] || echo "maven package failed"
	log_file "maven package is completed ------------>"
}

#shutdown tomcat
function shutdown_tomcat(){
	cd $TOMCAT_HOME
	#not recommend
	#bin/shutdown.sh

	ps -ef|grep "tomcat"|grep $KILL_TOMCAT_KEYWORD|grep -v grep|awk '{print $2}'|xargs kill -9
	sleep 3s
	log_file "Tomcat service is stoped ------------>"
}

#deploy
function deploy(){
cd $TOMCAT_HOME
	cp $GIT_REPO/target/$APP_NAME.war $TOMCAT_HOME/webapps
	$JAVA_HOME/bin/jar xf $TOMCAT_HOME/webapps/$APP_NAME.war
	sleep 2s
	log_file "war deploy completed ------------>"
}

#start tomcat
function start_tomcat(){
	cd $TOMCAT_HOME
	bin/startup.sh
	log_file "Tomcat service is starting ------------>"
	sleep 20s
}

#tomcat status check
function check_tomcat_status(){
	HTTP_CODE=`curl -o /dev/null -s -m 30 --connect-timeout 30 -w %{http_code} $TEST_URL`
	HTTP_CODE_PRE=${HTTP_CODE:0:1}

	if [[ $HTTP_CODE_PRE -eq 2||$HTTP_CODE_PRE -eq 3 ]]
	then
		log_file "------------ Tomcat service is working fine ------------"
	else
		log_file "------------ Tomcat service startup faild, HTTP_CODE is: $HTTP_CODE ------------"
	fi
}

#log
function log_file(){
	echo -e "`date '+%Y-%m-%d %H:%M:%S': `$1"|tee -a  $AUTODEPLOY_LOG_FILE
}
function fail(){
	log_s "$1" 
	log_s "operation faild, check the log and try again please."
	exit -1
} 
# Exits if given directory doesn't exist
function check_dir(){
	[ -d $1 ] || fail "Directory $1 doesn't exist!";
}


#run function
update_code
package
shutdown_tomcat
deploy
start_tomcat
check_tomcat_status
