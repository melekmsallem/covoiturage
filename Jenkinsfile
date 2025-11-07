node {
  stage('SCM') {
    checkout scm
  }

  stage('SonarQube Analysis') {
    withSonarQubeEnv() {
      sh 'chmod +x gradlew'
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
}
