pipeline {
    agent any

    environment {
        REGISTRY_URL = 'dev-overay-studio-server.kr.ncr.ntruss.com'
        REGISTRY_CREDENTIALS_ID = 'ncloud-credentials'
        DOCKER_IMAGE = 'nest-server'
        TAG_IMAGE = 'dev-nest-server'
        SERVER_IP = '192.168.1.6'
        IMAGE_TAG = "${env.BUILD_ID}" // 각 빌드마다 고유한 ID를 태그로 사용
        SSH_USER = 'root'
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
                    if ! command -v node &> /dev/null; then
                      echo "NodeJS could not be found. Installing..."
                      apk update && apk add --no-cache nodejs npm
                    fi

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
                        sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG .'
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
                    sh 'docker tag $DOCKER_IMAGE:$IMAGE_TAG $REGISTRY_URL/$TAG_IMAGE:$IMAGE_TAG'
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
                    withCredentials([usernamePassword(credentialsId: REGISTRY_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh 'echo $DOCKER_PASSWORD | docker login $REGISTRY_URL -u $DOCKER_USERNAME --password-stdin'
                    }
                
                    sh 'echo image pushed is $REGISTRY_URL/$TAG_IMAGE:$IMAGE_TAG'
                    sh 'docker push $REGISTRY_URL/$TAG_IMAGE:$IMAGE_TAG'
                }
            }

            post {
                failure {
                    sh 'echo "Push to registry failed"'
                }
            }
        }

        stage("Remove images") {
            steps {
                script {
                    sh 'echo "docker images"'
                    sh 'echo remove images all'
                    sh 'docker image prune -f -a'
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: REGISTRY_CREDENTIALS_ID, passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh '''
                            ssh -T -i $KEY_PATH -o StrictHostKeyChecking=no $SSH_USER@$SERVER_IP <<EOF
                                export DOCKER_USERNAME=$DOCKER_USERNAME
                                export DOCKER_PASSWORD=$DOCKER_PASSWORD
                                export REGISTRY_URL=$REGISTRY_URL
                                export TAG_IMAGE=$TAG_IMAGE
                                export IMAGE_TAG=$IMAGE_TAG


                                echo \\\$DOCKER_PASSWORD | docker login \\\$REGISTRY_URL -u \\\$DOCKER_USERNAME --password-stdin
                                docker pull \\\$REGISTRY_URL/\\\$TAG_IMAGE:\\\$IMAGE_TAG

                                # Stop and remove existing container with the same name
                                docker ps -aq -f name=nestjs-docker

                                docker_container_command="docker ps -aq -f name=nestjs-docker"

                                echo "it is??.. $docker_container_command"
                                docker stop \\\$(docker ps -aq -f name=nestjs-docker) || true
                                docker rm \\\$(docker ps -aq -f name=nestjs-docker) || true

                                docker ps 
                                docker ps -a
                            

                                # Run the new container
                                echo "Running docker container: \\\$REGISTRY_URL/\\\$TAG_IMAGE:\\\$IMAGE_TAG"
                                docker run -d -p 3000:3000 --name nestjs-docker \\\$REGISTRY_URL/\\\$TAG_IMAGE:\\\$IMAGE_TAG

                                echo "running container"
                                docker ps

                                # Clean up unused images
                                echo "=== clean image ==="
                                docker image prune -a -f
EOF
                        '''
                    }
                }
            }
            post {
                failure {
                    sh 'echo "Deploy failed"'
                }
            }
        }
    }

    post {
        always {
            sh '''
                echo "Final cleanup..."
                docker system prune -a -f --volumes
                echo "Pipeline completed"
            '''
        }
    }
}