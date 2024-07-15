pipeline {
    agent {
        docker {
            image 'docker:19.03.12-dind' // Docker-in-Docker 이미지 사용
            args '--privileged -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        REGISTRY_URL = 'https://ncloudregistry.com'
        REGISTRY_CREDENTIALS_ID = 'ncloud-credentials'
        SSH_CREDENTIALS_ID = 'ncloud-ssh-credentials'
        DOCKER_IMAGE = 'nest-server'
        TAG_IMAGE = 'dev-nest-server'
        PUBLIC_SUBNET_IP = 'your-public-subnet-ip'
        IMAGE_TAG = "${env.BUILD_ID}" // 각 빌드마다 고유한 ID를 태그로 사용
        SSH_USER = 'your-username'
        GITHUB_URL = 'https://github.com/xxx-sj/nest-jenkins-sample.git'
    }

    tools {
        nodejs 'nodeJS' // Jenkins에 설치된 NodeJS 툴 이름
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'master',
                    url: "${GITHUB_URL}"
            }

            post {
                success {
                    sh 'echo "Successfully cloned from git repo"'
                }
                failure {
                    sh 'echo "fail cloned from git"'
                }
            }
        }
        
        stage('Setup Docker and NodeJS') {
            steps {
                sh '''
                    apk update &&
                    apk add --no-cache openrc &&
                    apk add --no-cache docker &&
                    rc-update add docker boot &&
                    service docker start &&
                    dockerd &

                    # Docker 데몬이 시작될 때까지 대기
                    while (! docker info > /dev/null 2>&1); do
                      echo "Waiting for Docker Daemon to start..."
                      sleep 1
                    done

                    # Jenkins 사용자를 Docker 그룹에 추가
                    addgroup -S docker || true
                    adduser -S jenkins || true
                    addgroup jenkins docker || true

                    docker --version
                '''
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
            }

            post {
                failure {
                    sh 'echo "build failed"'
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }

            post {
                failure {
                    sh 'echo "test failed"'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
                }
            }

            post {
                failure {
                    sh 'echo "Build Docker image failed"'
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                script {
                    sh "docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${REGISTRY_URL}/${TAG_IMAGE}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Push to ncloud registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: REGISTRY_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "echo ${DOCKER_PASSWORD} | docker login ${REGISTRY_URL} -u ${DOCKER_USERNAME} --password-stdin"
                    }
                    sh "docker push ${REGISTRY_URL}/${TAG_IMAGE}:${IMAGE_TAG}"
                }
            }

            post {
                failure {
                    sh 'echo "Push to registry failed"'
                }
            }
        }
        
        stage('Deploy to Public Subnet') {
            steps {
                sshagent([SSH_CREDENTIALS_ID]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${SSH_USER}@${PUBLIC_SUBNET_IP} << EOF
                    docker pull ${REGISTRY_URL}/${TAG_IMAGE}:${IMAGE_TAG}
                    docker run -d -p 3001:3001 ${REGISTRY_URL}/${TAG_IMAGE}:${IMAGE_TAG}
                    EOF
                    """
                }
            }

            post {
                failure {
                    sh 'echo "Deploy failed"'
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    # Docker 이미지 및 컨테이너 정리
                    docker system prune -a -f --volumes

                    # 임시 파일 및 캐시 정리
                    rm -rf /tmp/*
                    rm -rf /var/cache/apk/*
                '''
            }
        }
    }
}