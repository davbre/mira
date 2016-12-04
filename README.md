# Mira

Mira is a Ruby on Rails application which gives you a simple HTTP API for CSV files.

## Summary

1. You create a Mira *project*. A project is simply a home for one or more CSV files, along with a datapackage.json file. More on that now...

2. You provide Mira with information about your CSV files by uploading a datapackage.json file to the project. This file provides metadata for the CSV files you plan to upload to the project. i.e. file names, columns names and types, delimiters etc. See [here](http://data.okfn.org/doc/tabular-data-package) and [here](http://dataprotocols.org/tabular-data-package/) for more information about datapackage.json files and tabular data packages.

3. With the datapackage.json file Mira then does the following:
    - it creates an empty database table for each CSV file specified in the datapackage.json file.
    - it creates an API to these database tables which you can use to read and write data.

4. You write data to the database tables by uploading CSV files, or by using a JSON API.

5. You can query the data using simple API requests. Consider a table `mytable` in a project, with columns `col1`, `col2` and `col3`. To get rows where `col1` equals "XXX", `col2` equals "YYY" and `col3` equals "ZZZ", you could make the following `GET` request:

  <pre>
  http://localhost:3000/api/projects/1/tables/mytable/data?<b>col1_eq=XXX&col2_eq=YYY&col3_eq=ZZZ</b>
  </pre>

  See the demo for more details on how the data can be queried.

6. You can generate API keys to control the reading and writing data.

## Demo

A Mira instance is running here providing APIs to several datasets:

[http://178.62.193.189](http://178.62.193.189)

For example, some [dummy clinical trial data](https://github.com/davbre/dummy-sdtm/tree/master/output/mira_sample_data) has been uploaded and its API details are found here:

[http://178.62.193.189/projects/6/api-details](http://178.62.193.189/projects/6/api-details)

Some examles of interacting with a Mira API:

[http://davbre.github.io/mira-examples/](http://davbre.github.io/mira-examples/)


## Quick Start

#### Pre-requisites
- You're familiar with [Ruby](https://www.ruby-lang.org/en/) and [Ruby on Rails](http://rubyonrails.org/).

- PostgreSQL is installed

  [https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04] (https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04)


---

1. Clone the repository

2. Run bundle

        bundle install

3. Update the config/database.yml file with your database credentials. Assuming you've created a user "mira" with full access to a database of the same name:

        default: &default
          adapter: postgresql
          encoding: unicode
          pool: 5
          host: localhost
          port: 5432
          username: mira
          password: **your_password_here**

        development:
          <<: *default
          database: mira_dev

        test:
          <<: *default
          database: mira_test

4. Create and migrate database, and seed database with a single admin user (email = admin@example.com and password = topsecret):

        rake db:create
        rake db:migrate
        rake db:seed

5. Start your local development server

        rails s

6. In a separate terminal start a background job to process uploaded files

        rake jobs:work

7. Open up the Mira homepage:

    [http://localhost:3000] (http://localhost:3000)

8. Download sample csv files + their datapackage.json file:

    [mira_sample_data.tar.gz] (https://github.com/davbre/dummy-sdtm/blob/master/output/mira_sample_data/mira_sample_data.tar.gz)
    or
    [mira_sample_data.zip] (https://github.com/davbre/dummy-sdtm/blob/master/output/mira_sample_data/mira_sample_data.zip)

9. Log in, create a new project, first upload the datapackage.json file, then the sample csv files

10. Navigate to the following address for the project's API details:

    [http://localhost:3000/projects/1/api-details](http://localhost:3000/projects/1/api-details)


## Extra Notes

Assuming a write API key has been generated, here's how you can write data:

curl -d "data[col1]=value1&data[col2]=val2" -H "X-Api-Key: 6041fa394bc84abe46ffdb71" http://localhost:3000/api/projects/1/tables/mytable/data
