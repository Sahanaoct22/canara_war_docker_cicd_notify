pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = 'sahanavnaik2210'
        DOCKER_IMAGE = "${DOCKERHUB_USERNAME}/canara_sak"
        DOCKER_CONTAINER = 'canara_app_sak'
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'prod'],
            description: 'Select deployment environment'
        )
        choice(
            name: 'ACTION',
            choices: ['deploy', 'remove'],
            description: 'Select action to perform'
        )
        string(
            name: 'RECEIVER_EMAIL',
            defaultValue: 'sahanavnaik2210@gmail.com',
            description: 'Email to receive pipeline notifications'
        )
    }

    stages {

        /* ================= DEV DEPLOY ================= */

        stage('Run in the Dev Environment') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'dev' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                echo 'Deploying to Development Environment'
                sh '''
                    sudo docker-compose down || true
                    sudo docker-compose up -d --build
                '''
            }
            post {
                success {
                    notifyEmail("DEV ENV DEPLOY SUCCESS")
                }
                failure {
                    notifyEmail("DEV ENV DEPLOY FAILURE")
                }
            }
        }

        /* ================= DEV REMOVE ================= */

        stage('Remove container in Dev Environment') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'dev' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                echo 'Removing Development Environment'
                sh '''
                    sudo docker-compose down || true
                    sudo docker system prune -af
                '''
            }
            post {
                success {
                    notifyEmail("DEV ENV REMOVE SUCCESS")
                }
                failure {
                    notifyEmail("DEV ENV REMOVE FAILURE")
                }
            }
        }

        /* ================= PROD BUILD ================= */

        stage('Build Docker Image') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                sh 'sudo docker build -t $DOCKER_IMAGE:latest .'
            }
        }

        stage('Login to Docker Hub') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-hub-cred',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_PASS'
                    )
                ]) {
                    sh 'echo $DOCKERHUB_PASS | sudo docker login -u $DOCKERHUB_USER --password-stdin'
                }
            }
        }

        stage('Docker Tag with Build ID') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                sh 'sudo docker tag $DOCKER_IMAGE:latest $DOCKER_IMAGE:${BUILD_ID}'
            }
        }

        stage('Push Docker Images') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                sh '''
                    sudo docker push $DOCKER_IMAGE:latest
                    sudo docker push $DOCKER_IMAGE:${BUILD_ID}
                '''
            }
        }

        stage('Logout from Docker Hub') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                sh 'sudo docker logout'
            }
        }

        stage('Clean Up Local Docker Images') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                sh '''
                    sudo docker rmi $DOCKER_IMAGE:${BUILD_ID} || true
                    sudo docker image prune -af
                '''
            }
        }

        /* ================= PROD DEPLOY ================= */

        stage('Deploy Docker Container in Production Server') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'deploy' }
                }
            }
            steps {
                sh '''
                    echo "Pulling latest image..."
                    sudo docker pull $DOCKER_IMAGE:latest

                    if [ "$(sudo docker ps -aq -f name=$DOCKER_CONTAINER)" ]; then
                        sudo docker rm -f $DOCKER_CONTAINER
                    fi

                    sudo docker run -d \
                        --restart always \
                        --name $DOCKER_CONTAINER \
                        -p 8085:8080 \
                        $DOCKER_IMAGE:latest
                '''
            }
            post {
                success {
                    notifyEmail("PROD ENV DEPLOY SUCCESS")
                }
                failure {
                    notifyEmail("PROD ENV DEPLOY FAILURE")
                }
            }
        }

        /* ================= PROD REMOVE ================= */

        stage('Remove Docker Container in Production Server') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    expression { params.ACTION == 'remove' }
                }
            }
            steps {
                sh '''
                    if [ "$(sudo docker ps -aq -f name=$DOCKER_CONTAINER)" ]; then
                        sudo docker rm -f $DOCKER_CONTAINER
                    fi

                    sudo docker rmi -f $DOCKER_IMAGE:latest || true
                '''
            }
            post {
                success {
                    notifyEmail("PROD ENV REMOVE SUCCESS")
                }
                failure {
                    notifyEmail("PROD ENV REMOVE FAILURE")
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs.'
        }
    }
}

/* ================= EMAIL NOTIFICATION FUNCTION ================= */

def notifyEmail(status) {
    script {
        withCredentials([
            string(credentialsId: 'gmail-app-password', variable: 'GMAIL_APP_PASS')
        ]) {
            sh """
            chmod +x jenkins_notify.sh || true

            GMAIL_USER=sahanavnaik2210@gmail.com \
            GMAIL_APP_PASS=\$GMAIL_APP_PASS \
            ./jenkins_notify.sh "${status}" "${JOB_NAME}" "${BUILD_NUMBER}" "${RECEIVER_EMAIL}"
            """
        }
    }
}
