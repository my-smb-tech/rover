Describe 'ci.sh'
  Include scripts/ci.sh
  Include scripts/functions.sh
  Describe "verify_ci_parameters"
    #Function Mocks
    error() {
        local parent_lineno="$1"
        local message="$2"
        >&2 echo "Error line:${parent_lineno}: message:${message} status :${code}"
        return ${code}
    }

    Context "No Symphony Yaml Provided"
      setup() {
        unset symphony_yaml_file
      }
      BeforeEach 'setup'

      It 'should return an error that the path to symphony.yml is not provided'
        When call verify_ci_parameters
        The output should eq '@Verifying ci parameters'
        The error should eq 'Error line:1: message:Missing path to symphony.yml. Please provide a path to the file via -sc or --symphony-config status :1'
        The status should eq 1
      End
    End

    Context "Symphony Yaml Provided, invalid file"
      setup() {
        export symphony_yaml_file="spec/harness/symphony2.yml"
        export base_directory="."
      }
      BeforeEach 'setup'

      It 'should return an error if the symphony yaml path points to an invalid or missing file'
        When call verify_ci_parameters
        The output should eq '@Verifying ci parameters'
        The error should eq 'Error line:1: message:Invalid path, spec/harness/symphony2.yml file not found. Please provide a valid path to the file via -sc or --symphony-config status :1'
        The status should eq 1
      End
    End


    Context "Symphony Yaml Provided, valid file"
      Describe "tasks registered"
        setup() {
          register_ci_tasks # > /dev/null 2>&1
          export symphony_yaml_file="spec/harness/symphony.yml"
          export base_directory="."
          #create dummy dirs
          mkdir -p ./spec/harness/landingzones/launchpad
          touch ./spec/harness/landingzones/launchpad/main.tf

          mkdir -p ./spec/harness/configs/level0/launchpad
          touch ./spec/harness/configs/level0/launchpad/configuration.tfvars
        }
        teardown(){
          rm -rf ./spec/harness/configs/level0/launchpad
          rm -rf ./spec/harness/landingzones/launchpad
        }
        BeforeEach 'setup'
        AfterEach 'teardown'

        It 'should return no errors if symphony yaml is valid and ci tasks are registered'
          When call verify_ci_parameters
          The output should include '@Verifying ci parameters'
          The output should include '@ starting validation of symphony yaml. path:'
          The error should eq ''
          The status should eq 0
        End
      End

      Describe "no tasks registered"
        setup() {
          CI_TASK_CONFIG_FILE_LIST=()
          REGISTERED_CI_TASKS=()
          export symphony_yaml_file="spec/harness/symphony.yml"
          export base_directory="."
          export ci_task_name='task1'
          export CI_TASK_DIR='spec/harness/ci_tasks/'
          register_ci_tasks
        }
        Before 'setup'

        It 'should return no errors if symphony yaml is valid and ci tasks are registered'
          When call verify_ci_parameters
          The error should include ''
          The output should include '@Verifying ci parameters'
          The status should eq 0
        End
      End

    End

  End

  Describe "execute_ci_actions"
    Context "Happy path validation"
      get_all_level_names() {
        echo "level1"
      }
      get_all_stack_names_for_level() {
        echo "foundations"
      }
      get_landingzone_path_for_stack() {
        echo "caf_modules_public/landingzones/caf_foundations/"
      }
      run_task() {
        echo "run_task arguments: $@";
        return 0
      }

      setup() {
        export symphony_yaml_file="spec/harness/symphony.yml"
        export base_directory="."
      }
      Before 'setup'

      It 'should return no errors'
        When call execute_ci_actions
        The output should include "@Starting CI tools execution"
        The output should include "All CI tasks have run successfully."
        The error should eq ''
        The status should eq 0
      End
    End
  End

End