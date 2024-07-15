pipeline {
    agent any

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



    stages {
        stage('Checkout') {
            steps {
                git branch 'master'
                url ${GITHUB_URL}
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
        
        stage('Build') {
            steps {
                // 빌드 명령어 예시
                sh 'make build'
            }

            post {
                failure {
                    sh 'build failed'
                }
            }
        }
        
        stage('Test') {
            steps {
                // 테스트 명령어 예시
                sh 'make test'
            }

            post {
                failure {
                    sh 'test failed'
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
                    sh 'build coker image failed'
                }
            }
        }

        stage("Tag docker image") {
            steps {
                script {
                    sh "docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${REGISTRY_URL}/${TAG_IMAGE}:${IMAGE_TAG}"
                }
            }
        }
        
        stage('Push to ncloud registry') {
            steps {
                script {
                    docker login dev-overay-studio-server.kr.ncr.ntruss.com
                    docker push dev-overay-studio-server.kr.ncr.ntruss.com/${TAG_IMAGE}
                    // docker pull dev-overay-studio-server.kr.ncr.ntruss.com/<TARGET_IMAGE[:TAG]>
                }

                post {
                    failure {
                        sh 'push registry failed'
                    }
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
                    docker pull ${DOCKER_IMAGE}
                    docker run -d -p 3001:3001 ${DOCKER_IMAGE}
                    EOF
                    """
                }
            } 
            post {
                failure {
                    sh 'deploy failed'
                }
            }

        }
    }
}