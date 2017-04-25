pipeline {
  agent any
  stages {
    stage('GitHub') {
      steps {
        archiveArtifacts(allowEmptyArchive: true, artifacts: '**')
      }
    }
  }
}