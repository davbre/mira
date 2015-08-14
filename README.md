# Mira

Mira takes CSV files and gives you a read-only HTTP API.

Upload CSV files along with a corresponding tabular data package (a datapackage.json file). The datapackage.json file provides the CSV file metadata, i.e. file names, columns, column-types, delimiters etc. See [here](http://data.okfn.org/doc/tabular-data-package) and [here](http://dataprotocols.org/tabular-data-package/) for more information on tabular data packages.

## Demo
http://178.62.7.111

## Quick Start

1. Clone the repository

2. Run bundle

        bundle install

3. Create and migrate database

        rake db:create
        rake db:migrate
        
4. Seed the database with the single admin user, email = admin@example.com and password = topsecret

        rake db:seed

5. Start your local development server

        rails s

6. Navigate to http://localhost:3000

5. Log in, create a new project, upload csv files along with their corresponding datapackage.json file.

