pipeline {
  agent any
  stages {
    stage('Get Artifacts') {
      steps {
        archiveArtifacts '**'
      }
    }
    stage('Unit Tests') {
      steps {
        echo 'Test Codes'
      }
    }
    stage('Copy Artifacts') {
      steps {
        echo 'Copy_Artifacts'
      }
    }
    stage('Post Deployment Operations') {
      steps {
        echo 'Post deployment operations will be made here'
      }
    }
    stage('UI - API Tests') {
      steps {
        echo 'Deployment Result'
      }
    }
  }
}
