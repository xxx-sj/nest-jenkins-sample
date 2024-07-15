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


    tools {
        // NodeJS 설치 (Jenkins에 NodeJS Plugin이 설치되어 있어야 합니다)
        nodejs 'NodeJS'
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
        
        stage('Build') {
            steps {
                // npm 명령어를 사용하여 빌드
                sh 'npm install'
                sh 'npm run build'
            }

            post {
                failure {
                    sh 'build failed'
                }
            }
        }
        
        stage('Test') {
            steps {
                // npm 명령어를 사용하여 테스트
                sh 'npm test'
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