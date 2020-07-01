docker rmi la1r/jenkins
docker build . -t la1r/jenkins
docker run --rm -it -v $pwd/:/seb -v $pwd/jenkins.yaml:/var/jenkins_home/casc_configs/jenkins.yaml -p 8080:8080 -p 50000:50000 la1r/jenkins
