

Rails::TestTask.new("test:controllers" => "test:prepare") do |t|
  t.pattern = "test/controllers/**/*_test.rb"
end

Rails::TestTask.new("test:models" => "test:prepare") do |t|
  t.pattern = "test/models/**/*_test.rb"
end