pipeline {
    agent any

    stages {

        stage('Checkout App Code') {
            steps {
                echo 'Cloning application repository...'
                dir('app') {
                    git branch: 'main',
                        url: 'https://github.com/AbdullahTanveerOfficial/sir-qasim-3.git'
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
                echo 'Building and starting containers...'
                dir('app') {
                    sh 'docker compose up -d --build'
                }
                echo 'Waiting 40 seconds for app to be ready...'
                sh 'sleep 40'
            }
        }

        stage('Run Selenium Tests') {
            steps {
                echo 'Running Selenium tests inside Docker...'
                dir('app/selenium-tests') {
                    sh '''
                        docker run --rm \
                            --network host \
                            -v $(pwd):/workspace \
                            -w /workspace \
                            markhobson/maven-chrome:jdk-11 \
                            mvn test -Dapp.url=http://localhost:3000
                    '''
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
                echo 'Bringing deployment down...'
                dir('app') {
                    sh 'docker compose down'
                }
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

                // If email is noreply, fallback to teacher's email
                if (committerEmail.contains('noreply')) {
                    committerEmail = 'qasimalik@gmail.com'
                }

                def buildStatus = currentBuild.result ?: 'SUCCESS'

                emailext(
                    subject: "Jenkins Build ${buildStatus}: TaskFlow Tests - Build #${env.BUILD_NUMBER}",
                    body: """
                        <h2>Jenkins Pipeline Result</h2>
                        <p><b>Build Number:</b> #${env.BUILD_NUMBER}</p>
                        <p><b>Status:</b> ${buildStatus}</p>
                        <p><b>Committed by:</b> ${committerEmail}</p>
                        <p><b>Build URL:</b> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                        <h3>Selenium Test Results attached above</h3>
                    """,
                    to: committerEmail,
                    mimeType: 'text/html'
                )
            }
        }
    }
}