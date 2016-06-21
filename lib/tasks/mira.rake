namespace :mira do
  namespace :dev do

    desc "Reset dev database and clear out uploads and logs"
    task :reset do
      system("sudo service postgresql restart")
      begin
        Rake::Task["db:drop"].invoke
      rescue Exception => e
        puts "Database not dropped: " + e.message
      end
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
      system ("find #{Rails.root.to_s}/project_files/uploads/ -name \"*.csv\" -type f -delete")
      system ("find #{Rails.root.to_s}/project_files/uploads/ -name \"*.json\" -type f -delete")
      system ("find #{Rails.root.to_s}/project_files/job_logs/ -name \"*.log\" -type f -delete")
      # remove empty directories
      system("find #{Rails.root.to_s}/project_files/uploads/ -depth -type d -empty -exec rmdir {} \\;")
      system("find #{Rails.root.to_s}/project_files/job_logs/ -depth -type d -empty -exec rmdir {} \\;")
      system("> #{Rails.root}/log/development.log")
    end

  end
end
