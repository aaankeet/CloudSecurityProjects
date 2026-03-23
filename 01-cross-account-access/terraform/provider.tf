provider "aws" {
  alias   = "security"
  region  = "us-east-1"
  profile = "security-account"
}

provider "aws" {
  alias   = "workload"
  region  = "us-east-1"
  profile = "workload-account"
}
