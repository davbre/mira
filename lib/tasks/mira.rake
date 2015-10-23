namespace :mira do
  namespace :dev do

    desc "Reset dev database and clear out uploads and logs"
    task :reset do
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
      system ("find #{Rails.public_path.to_s}/uploads/ -name \"*.csv\" -type f -delete")
      system ("find #{Rails.public_path.to_s}/uploads/ -name \"*.json\" -type f -delete")
      system ("find #{Rails.public_path.to_s}/job_logs/ -name \"*.log\" -type f -delete")
      # remove empty directories
      system("find #{Rails.public_path.to_s}/uploads/ -depth -type d -empty -exec rmdir {} \\;")
      system("find #{Rails.public_path.to_s}/job_logs/ -depth -type d -empty -exec rmdir {} \\;")
      system("> #{Rails.root}/log/development.log")
    end

  end
end
