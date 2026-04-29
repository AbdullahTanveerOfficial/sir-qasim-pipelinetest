pipeline {
    agent any

    environment {
        APP_REPO = 'https://github.com/AbdullahTanveerOfficial/sir-qasim-3.git'
        APP_URL  = "http://${env.EC2_PUBLIC_IP}:3000"
        EC2_IP   = sh(script: 'curl -s http://169.254.169.254/latest/meta-data/public-ipv4', returnStdout: true).trim()
    }

    stages {

        stage('Checkout App Code') {
            steps {
                echo 'Cloning application repository...'
                dir('app') {
                    git branch: 'main', url: "${APP_REPO}"
                }
            }
        }

        stage('Stop Existing Deployment') {
            steps {
                echo 'Stopping any existing containers...'
                dir('app') {
                    sh 'docker compose down || true'
                }
            }
        }

        stage('Build & Deploy Application') {
            steps {
                echo 'Building Docker image and starting containers...'
                dir('app') {
                    sh 'docker compose up -d --build'
                }
                echo 'Waiting 30 seconds for app to be ready...'
                sh 'sleep 30'
            }
        }

        stage('Run Selenium Tests') {
            steps {
                echo 'Running Selenium tests in containerized environment...'
                dir('app/selenium-tests') {
                    sh """
                        docker run --rm \
                            --network host \
                            -v \$(pwd):/workspace \
                            -w /workspace \
                            -e app.url=http://localhost:3000 \
                            markhobson/maven-chrome:jdk-11 \
                            mvn test -Dapp.url=http://localhost:3000
                    """
                }
            }
            post {
                always {
                    junit 'app/selenium-tests/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Stop Deployment') {
            steps {
                echo 'Stopping containers after test...'
                dir('app') {
                    sh 'docker compose down'
                }
                echo 'Deployment is down as required.'
            }
        }
    }

    post {
        always {
            script {
                def committerEmail = sh(
                    script: "cd app && git log -1 --pretty=format:'%ae'",
                    returnStdout: true
                ).trim()

                def buildStatus = currentBuild.result ?: 'SUCCESS'
                def subject = "Jenkins Build ${buildStatus}: TaskFlow Tests - Build #${env.BUILD_NUMBER}"
                def body = """
                    <h2>Jenkins Pipeline Result</h2>
                    <p><b>Build:</b> #${env.BUILD_NUMBER}</p>
                    <p><b>Status:</b> ${buildStatus}</p>
                    <p><b>Triggered by commit from:</b> ${committerEmail}</p>
                    <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <h3>Test Results</h3>
                    <p>See attached build for full Selenium test report.</p>
                """

                emailext(
                    subject: subject,
                    body: body,
                    to: committerEmail,
                    mimeType: 'text/html'
                )
            }
        }
    }
}