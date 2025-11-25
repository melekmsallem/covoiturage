properties([
  pipelineTriggers([
    cron('H 3 * * *'),          // Daily schedule
    githubPush()                // Fire on GitHub webhook events
  ])
])

node {
  stage('Prepare Workspace') {
    deleteDir()
  }
  def dockerRepository = env.DOCKER_REPOSITORY ?: 'yourdockerhubuser/covoiturage-final'
  def nexusRepoUrl = env.NEXUS_REPOSITORY_URL ?: 'http://localhost:8083/repository/maven-releases/'
  def buildTag = env.BUILD_NUMBER ?: (env.BUILD_ID ?: 'local')
  def versionedImage = "${dockerRepository}:${buildTag}"
  def latestImage = "${dockerRepository}:latest"

  stage('SCM') {
    checkout scm
  }

  stage('Build & Unit Tests') {
    sh 'chmod +x gradlew'
    sh './gradlew clean build -x test'
  }

  stage('SonarQube Analysis') {
    withSonarQubeEnv('sonar-local') {
      sh "./gradlew sonar"
    }
  }

  stage('Quality Gate') {
    timeout(time: 1, unit: 'HOURS') {
      def qg = waitForQualityGate()
      if (qg.status != 'OK') {
        error "Pipeline aborted due to quality gate failure: ${qg.status}"
      }
    }
  }

  stage('Publish Artifact to Nexus') {
    withCredentials([usernamePassword(credentialsId: 'nexus-admin', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
      sh """
        ./gradlew publish \\
          -PnexusUsername=${NEXUS_USER} \\
          -PnexusPassword=${NEXUS_PASS} \\
          -PnexusRepositoryUrl=${nexusRepoUrl}
      """
    }
  }

  stage('Docker Build') {
    sh "docker build -t ${versionedImage} --build-arg JAR_FILE=build/libs/covoiturage-final.jar ."
  }

  stage('Docker Push') {
    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
      sh """
        echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin
        docker tag ${versionedImage} ${latestImage}
        docker push ${versionedImage}
        docker push ${latestImage}
      """
    }
  }

  stage('Deploy with Docker Compose') {
    sh """
      docker network create cicd-net || true
      APP_IMAGE=${versionedImage} docker compose -f infra/docker-compose.app.yml down || true
      APP_IMAGE=${versionedImage} docker compose -f infra/docker-compose.app.yml up -d
    """
  }

  stage('Cleanup') {
    sh 'docker image prune -f || true'
  }
}
