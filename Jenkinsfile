pipeline {
  agent any
  stages {
    stage('GitHub') {
      steps {
        archiveArtifacts(allowEmptyArchive: true, artifacts: '**')
      }
    }
    stage('Test') {
      steps {
        echo 'testing scripts, keep calm!!'
      }
    }
    stage('Deploy To Dev') {
      steps {
        echo 'Deploying the files to Dev Environment'
      }
    }
  }
}