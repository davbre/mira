
Run all tests:
  rake test

Run tests in a folder:
  rake test test/models/*_test.rb

Run tests in single file:
  rake test test/models/project_test.rb

Run single test:
  ruby -I test test/controllers/datasources_controller_test.rb -n "test_name_of_test"



# Possible new tests...

      do not show uploads / datapackages when not logged in??

      test that private fields are not returned from API.
