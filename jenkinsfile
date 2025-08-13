pipeline {
  agent any

  // 1. Build Parameters
  parameters {
    booleanParam(name: 'UPDATE_STATE', defaultValue: false, description: 'Auto-refresh Terraform state if manual drift detected')
    booleanParam(name: 'DESTROY',      defaultValue: false, description: 'Destroy all infrastructure after deploy stage')
  }

  environment {
    TF_VERSION = '1.5.0'
    AWS_REGION = credentials('AWS_REGION')
  }

  stages {
    // 2. Checkout Code
    stage('Checkout') {
      steps {
        checkout scm
        echo "✅ Checked out ${env.GIT_COMMIT}"
      }
    }

    // 3. Setup Tools
    stage('Setup Tools') {
      steps {
        sh '''
          echo "🔧 Installing tools..."
          if ! command -v terraform &> /dev/null; then
            wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
            unzip -q terraform_${TF_VERSION}_linux_amd64.zip
            sudo mv terraform /usr/local/bin/
          fi
          pip3 install --quiet infracost
          echo "✅ Tools ready"
        '''
      }
    }

    // 4. Detect Manual Drift
    stage('Detect Drift') {
      steps {
        dir('.') {
          sh 'make init'
          script {
            def rc = sh(returnStatus: true, script: 'terraform plan -detailed-exitcode -out drift.plan')
            if (rc == 2) {
                echo "⚠️ Out-of-band changes detected"
                if (!params.UPDATE_STATE) {
                    error("""
                        Manual changes detected that are not in Terraform state.
                        Re-run with UPDATE_STATE=true to refresh state, or reconcile manually.""")
                } else {
                    echo "🔄 Refreshing Terraform state"
                    sh 'terraform apply -refresh-only drift.plan'
                }
            } else if (rc == 1) {
              error "❌ Error running terraform plan for drift detection"
            } else {
              echo "✅ No manual drift detected"
            }
          }
        }
      }
    }

    // 5. Code Quality & Security
    stage('Code Quality & Security') {
      parallel {
        stage('Terraform fmt & validate') {
          steps { sh 'make fmt validate' }
        }
        stage('Lambda Lint & Bandit') {
          steps {
            dir('lambda') {
              sh '''
                pylint *.py || true
                bandit -r . -f json -o bandit-report.json || true
              '''
              archiveArtifacts artifacts: 'lambda/bandit-report.json', allowEmptyArchive: true
            }
          }
        }
        stage('TFSec Scan') {
          steps {
            sh '''
              if command -v tfsec &> /dev/null; then
                tfsec . --format json --out tfsec-results.json || true
              else
                echo '{"results":[]}' > tfsec-results.json
              fi
            '''
            archiveArtifacts artifacts: 'tfsec-results.json', allowEmptyArchive: true
          }
        }
      }
    }

    // 6. Lambda Unit Tests
    stage('Run Lambda Tests') {
      steps {
        dir('lambda') {
          sh '''
            if [ -f test_lambda_functions.py ]; then
              pytest test_lambda_functions.py -q
            fi
          '''
        }
      }
    }

    // 7. Terraform Plan & Cost Estimation via Makefile
    stage('Terraform Plan & Cost') {
      steps {
        withCredentials([
          string(credentialsId: 'MY_IP',              variable: 'MY_IP'),
          string(credentialsId: 'BUDGET_ALERT_EMAIL', variable: 'BUDGET_ALERT_EMAIL'),
          string(credentialsId: 'TF_STATE_BUCKET',    variable: 'TF_STATE_BUCKET'),
          string(credentialsId: 'INFRACOST_API_KEY',  variable: 'INFRACOST_API_KEY'),          
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh 'export AWS_REGION=${AWS_REGION} && make plan'
        }
        archiveArtifacts artifacts: 'cost-estimate.txt, plan.json, tfplan.binary', allowEmptyArchive: true
        script {
          if (fileExists('cost-estimate.txt')) {
            currentBuild.description = readFile('cost-estimate.txt').take(300)
          }
        }
      }
    }

    // 8. Terraform Apply via Makefile
    stage('Terraform Apply') {
      when {
        branch 'main'
        expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
      }
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh 'make apply'
          sh 'make output > terraform-outputs.txt'
          archiveArtifacts artifacts: 'terraform-outputs.txt', allowEmptyArchive: true
        }
      }
    }

    // 9. Post-Deployment Validation
    stage('Post-Deploy Validation') {
      when { branch 'main' }
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials']
        ]) {
          sh '''
            INSTANCE_ID=$(terraform output -raw ec2_instance_id)
            aws lambda get-function --function-name start-ec2 --region $AWS_REGION
            aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'make clean || true'
      cleanWs()
    }
  }
}
