terraform {

  extra_arguments "common_vars" {
    commands = ["plan", "apply"]

    arguments = [
      "-var-file=./etc/bluedata_infra.tfvars",
      "-var=client_cidr_block=${run_cmd("curl", "-s", "http://ifconfig.me/ip")}/32" 
    ]
  }

  after_hook "write_output_json" {
    commands     = ["apply"]
    execute      = ["./bin/terraform_output.sh"]
    run_on_error = false
  }

  
}
