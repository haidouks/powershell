pipeline {
  agent any
  stages {
    stage('Get Codes') {
      steps {
        archiveArtifacts '**'
      }
    }
    stage('Copy Artifacts') {
      steps {
        writeFile(file: 'deneme.txt', text: 'bu bir denemedir')
      }
    }
  }
}