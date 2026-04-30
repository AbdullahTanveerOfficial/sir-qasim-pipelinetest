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
                    sh 'docker-compose down || true'
                    sh 'docker-compose rm -f || true'
                }
            }
        }

        stage('Build & Deploy Application') {
            steps {
                echo 'Building and starting containers...'
                dir('app') {
                    sh 'docker-compose up -d --build'
                }
                echo 'Waiting 60 seconds for app to be ready...'
                sh 'sleep 60'
                echo 'Verifying app is running...'

                // ✅ UPDATED: frontend now served via backend (port 5000)
                sh 'curl -f http://localhost:5000 || echo "App check done"'

                // backend health check remains
                sh 'curl -f http://localhost:5000/api/auth/me || echo "Backend check done"'
            }
        }

        stage('Seed Test User') {
            steps {
                echo 'Creating test user in database...'
                sh '''
                    curl -s -X POST http://localhost:5000/api/auth/register \
                        -H "Content-Type: application/json" \
                        -d "{\\"name\\":\\"Test User\\",\\"email\\":\\"testuser@taskflow.com\\",\\"password\\":\\"test123456\\"}" \
                        || echo "User may already exist, continuing..."
                '''
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
                            mvn test -Dapp.url=http://localhost:5000
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: 'app/selenium-tests/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Stop Deployment') {
            steps {
                echo 'Bringing deployment down...'
                dir('app') {
                    sh 'docker-compose down'
                }
                echo 'Deployment is down as required by assignment.'
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

                if (committerEmail.contains('noreply') || committerEmail.isEmpty()) {
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
