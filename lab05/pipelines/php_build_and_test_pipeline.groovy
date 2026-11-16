pipeline {
    agent {
        label 'php-agent'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Caffadras/usm-app-containerization.git', branch: 'lab05-phpunit'
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('containers08') {
                    sh 'composer install --no-interaction --no-progress'
                }
            }
        }

        stage('Test') {
            steps {
                dir('containers08') {
                    // failed tests mark the build UNSTABLE and let the Report stage still run
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        sh 'vendor/bin/phpunit --log-junit reports/junit.xml'
                    }
                }
            }
        }

        stage('Report') {
            steps {
                junit 'containers08/reports/junit.xml'
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo 'All tests passed.'
        }
        unstable {
            echo 'Some tests failed.'
        }
        failure {
            echo 'Errors detected in the pipeline.'
        }
    }
}
