pipeline {
  agent any
  stages {
    stage('Get Artifacts') {
      steps {
        archiveArtifacts '**'
      }
    }
    stage('Tests') {
    parallel {
      stage('Unit Tests') {		
          steps {		
            echo 'Test Codes'		
          }		
        }		
        stage('Code Quality Tests') {
          steps {
            powershell(encoding: 'UTF8', script: 'CD-CI/Modules/InputOutput/InvokeTests.ps1', returnStatus: true)
            //junit 'InputOutput/Tests/TestsResults.xml'
            step([$class: 'NUnitPublisher', testResultsPattern: 'CD-CI\\Modules\\InputOutput\\Tests\\TestsResults.xml', debug: false, keepJUnitReports: true, skipJUnitArchiver:false, failIfNoResults: true])
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