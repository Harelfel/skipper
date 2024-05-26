@Library('library')_

pipeline {
    agent {
        node {
            label 'jenkinsSlave'
        }
    }
    options {
        ansiColor('xterm')
        timestamps()
    }
        parameters {
        // Monkey branch for MonkeyTesting
        string(
            name: 'MONKEY_BRANCH',
            defaultValue: 'stable',
            description: 'Use Monkey at specific branch. For example: release_v22.02.0')
        // Monkey tests filter for MonkeyTesting
        string(
            name: 'MONKEY_TESTING_FILTER',
            defaultValue: '--regex inspector --excludeRegex upgrade',
            description: 'Tests filter for MonkeyTesting')
        // Monkey additional params for MonkeyTesting
        string(
            name: 'ADDITIONAL_MONKEY_PARAMS',
            defaultValue: '',
            description: 'Monkey additional parameters')
    }
    environment {
        // Get HEAD commit massage
        GIT_COMMIT_MSG = "${sh(script: 'git log -1 --pretty=%B ${GIT_COMMIT}', returnStdout: true).trim()}"
        // Get HEAD commit author
        GIT_AUTHOR = "${sh(script: 'git log -1 --pretty=%cn ${GIT_COMMIT}', returnStdout: true).trim()}"
        // Get HEAD commit email address
        GIT_AUTHOR_EMAIL = "${sh(script: 'git log -1 --pretty=%ae ${GIT_COMMIT}', returnStdout: true).trim()}"
        // Slack channel for notification
        SLACK_CHANNEL = '#zcompute-system-team-ci'
        // Integration ticket jira component
        JIRA_COMPONENT = 'Virtualization'
    }
    stages {
        // Init
        stage('Initialization') {
            steps {
                script {
                    // Get github organization name
                    env.GIT_ORG = sh(script: "echo $GIT_URL | awk -F/ '{print \$4}'", returnStdout: true).trim()
                    // Get git repository name
                    env.GIT_REPOSITORY = sh(
                        script: "echo $GIT_URL | awk -F/ '{print \$5}' | awk -F. '{print \$1}'",
                        returnStdout: true).trim()
                }
                sh 'printenv'
                // Set build name
                buildName "${env.BUILD_TAG}"
                // Set build description
                buildDescription "${env.GIT_URL} Branch: ${env.GIT_BRANCH} on Worker: ${env.NODE_NAME}"
            }
        }
        // Verify that all new commits are in standard
        stage('Verify commits') {
            when {
                changeRequest()
            }
            steps {
                verifyCommits()
            }
        }
        // Build the build container image
        stage('Build skipper image') {
            when {
                changeRequest()
            }
            steps {
                sh 'skipper build $GIT_REPOSITORY-build'
            }
        }
        stage('Service Subsystems tests') {
            when {
                changeRequest()
            }
            steps {
                sh 'skipper --build-container-tag $GIT_COMMIT make tests'
            }
        }
        stage('sonarCloud') {
            when {
                changeRequest()
            }
            steps {
                script{
                    def prBranch = env.CHANGE_BRANCH
                    def prBase = env.CHANGE_TARGET
                    def prKey = env.CHANGE_ID
                    def currentDir = pwd()
                    sh """
                        docker run \\
                            --rm \\
                            -e SONAR_HOST_URL="https://sonarcloud.io" \\
                            -e SONAR_SCANNER_OPTS="-Dsonar.projectKey=Harelfel_skipper -Dsonar.projectBaseDir=${currentDir} -Dsonar.python.coverage.reportPaths=coverage.xml -Dsonar.organization=harelfel -Dsonar.pullrequest.key=${prKey} -Dsonar.pullrequest.branch=${prBranch} -Dsonar.pullrequest.base=${prBase} -Dsonar.qualitygate.wait=true" \\
                            -e SONAR_TOKEN="654e8c7e6bb52a3fa3405c80e23998d50c1b0653" \\
                            -v "${currentDir}:${currentDir}" \\
                            sonarsource/sonar-scanner-cli
                    """
                }
            }
        }
    }
}