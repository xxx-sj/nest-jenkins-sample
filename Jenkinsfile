pipeline {
    agent any

    environment {
        REGISTRY_URL = 'dev-overay-studio-server.kr.ncr.ntruss.com'
        REGISTRY_CREDENTIALS_ID = 'ncloud-credentials'
        SSH_CREDENTIALS_ID = 'ncloud-ssh-credentials'
        DOCKER_IMAGE = 'nest-server'
        TAG_IMAGE = 'dev-nest-server'
        PUBLIC_SUBNET_IP = 'your-public-subnet-ip'
        IMAGE_TAG = "${env.BUILD_ID}" // 각 빌드마다 고유한 ID를 태그로 사용
        SSH_USER = 'your-username'
        GITHUB_URL = 'https://github.com/xxx-sj/nest-jenkins-sample.git'
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
                    sh 'echo "Failed to clone from git repo"'
                }
            }
        }

        stage('Setup Node') {
            steps {
                sh '''
                    # NodeJS 설치 확인 및 경로 설정
                    if ! command -v node &> /dev/null; then
                      echo "NodeJS could not be found. Installing..."
                      apk update && apk add --no-cache nodejs npm
                    fi

                    # NodeJS 버전 확인
                    node --version
                    npm --version
                '''
            }

            post {
                failure {
                    sh 'echo "Setup node failed"'
                }
            }
        }

        stage('Build') {
            steps {
                sh 'npm install'
                sh 'npm run build'
            }

            post {
                failure {
                    sh 'echo "Build failed"'
                }
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }

            post {
                failure {
                    sh 'echo "Test failed"'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} ."
                    } catch (Exception e) {
                        sh 'echo "Docker build failed with error: ${e}"'
                        throw e
                    }
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
                    //TODO docker tag nest-server:48 dev-overay-studio-server.kr.ncr.ntruss.com/sample/dev-nest-server:48 will tag change
                    sh "docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${REGISTRY_URL}/${TAG_IMAGE}:${IMAGE_TAG}"
                }
            }

            post {
                failure {
                    sh 'echo "Tag Docker image failed"'
                }
            }
        }

        stage('Push to ncloud registry') {
            steps {
                script {

                    // sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} dev-overay-studio-server.kr.ncr.ntruss.com"
                    // sh "docker push ${REGISTRY_URL}/${TAG_IMAGE}:${IMAGE_TAG}"
                    // sh "docker pull dev-overay-studio-server.kr.ncr.ntruss.com/<TARGET_IMAGE[:TAG]>"
                    
                    withCredentials([usernamePassword(credentialsId: REGISTRY_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login $REGISTRY_URL -u $DOCKER_USERNAME --password-stdin'
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