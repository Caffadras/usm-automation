pipeline {
    agent {
        label 'ansible-agent'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/Caffadras/usm-automation.git', branch: 'main'
            }
        }

        stage('Run Playbook') {
            steps {
                dir('lab05/ansible') {
                    // the SSH Agent plugin loads the test server key for the duration of the block
                    sshagent(credentials: ['ansible-test-server-key']) {
                        sh 'ansible-playbook setup_test_server.yml'
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline completed.'
        }
        success {
            echo 'Test server is configured.'
        }
        failure {
            echo 'Errors detected in the pipeline.'
        }
    }
}
