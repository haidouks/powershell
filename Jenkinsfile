pipeline {
  agent any
  stages {
    stage('Get Codes') {
      steps {
        sh 'echo deneme'
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
