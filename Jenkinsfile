node {
  stage('SCM') {
    checkout scm
  }

  stage('SonarQube Analysis') {
    withSonarQubeEnv() {
      sh "./gradlew sonar"
    }
  }
}
node {
  stage('SCM') {
    checkout scm
  }

  stage('SonarQube Analysis') {
    withSonarQubeEnv() {
      sh "./gradlew sonar"
    }
  }
}

