pipeline {
    agent {
        label 'ansible-agent'
    }

    stages {
        stage('Checkout') {
            steps {
                dir('app') {
                    git url: 'https://github.com/Caffadras/usm-app-containerization.git', branch: 'lab05-phpunit'
                }
                dir('automation') {
                    git url: 'https://github.com/Caffadras/usm-automation.git', branch: 'main'
                }
            }
        }

        stage('Deploy') {
            steps {
                dir('automation/lab05/ansible') {
                    sshagent(credentials: ['ansible-test-server-key']) {
                        sh 'ansible-playbook deploy_php_app.yml -e app_src=$WORKSPACE/app/containers08'
                    }
                }
            }
        }

        stage('Check') {
            steps {
                sh 'curl -fsS "http://test-server/?page=1" | grep "Page 1"'
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo 'Project is deployed: http://localhost:8081/?page=1'
        }
        failure {
            echo 'Errors detected in the pipeline.'
        }
    }
}
