pipeline {
  agent any
  stages {
    stage('Get Artifacts') {
      steps {
        archiveArtifacts '**'
      }
    }
    parallel {
      stage('Unit Tests') {		
          steps {		
            echo 'Test Codes'		
          }		
        }		
        stage('Code Quality Tests') {
          steps {
            powershell(encoding: 'UTF8', script: 'InputOutput/InvokeTests.ps1', returnStdout: true)
            junit 'InputOutput/Tests/TestsResults.xml'
          }
        }
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
