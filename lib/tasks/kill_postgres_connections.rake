# http://stackoverflow.com/a/5750734/1002140
# Relates to error:
#    PG::ObjectInUse: ERROR:  database "mira_dev" is being accessed by other users
task :kill_postgres_connections => :environment do
  suff = "dev" if "#{Rails.env}" == "development"
  db_name = "#{File.basename(Rails.root)}_"+ suff
  sh = <<EOF
ps xa \
  | grep postgres: \
  | grep #{db_name} \
  | grep -v grep \
  | awk '{print $1}' \
  | sudo xargs kill
EOF
  puts `#{sh}`
end

task "db:drop" => :kill_postgres_connections
