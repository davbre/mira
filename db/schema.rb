# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151030073834) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "datapackage_resource_fields", force: :cascade do |t|
    t.integer  "datapackage_resource_id"
    t.text     "name"
    t.text     "ftype"
    t.integer  "order"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.boolean  "big_integer"
  end

  add_index "datapackage_resource_fields", ["datapackage_resource_id"], name: "index_datapackage_resource_fields_on_datapackage_resource_id", using: :btree

  create_table "datapackage_resources", force: :cascade do |t|
    t.integer  "datapackage_id"
    t.text     "path"
    t.text     "format"
    t.text     "delimiter"
    t.text     "mediatype"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "datasource_id"
    t.text     "quote_character"
    t.text     "table_ref"
  end

  add_index "datapackage_resources", ["table_ref"], name: "index_datapackage_resources_on_table_ref", using: :btree

  create_table "datapackages", force: :cascade do |t|
    t.integer  "project_id"
    t.text     "public_url"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "datapackage_file_name"
    t.string   "datapackage_content_type"
    t.integer  "datapackage_file_size"
    t.datetime "datapackage_updated_at"
  end

  add_index "datapackages", ["project_id"], name: "index_datapackages_on_project_id", using: :btree

  create_table "datasources", force: :cascade do |t|
    t.string   "description"
    t.integer  "project_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "datafile_file_name"
    t.string   "datafile_content_type"
    t.integer  "datafile_file_size"
    t.datetime "datafile_updated_at"
    t.string   "db_table_name"
    t.text     "table_ref"
    t.text     "public_url"
    t.integer  "datapackage_id"
    t.integer  "import_status"
  end

  add_index "datasources", ["db_table_name"], name: "index_datasources_on_db_table_name", using: :btree
  add_index "datasources", ["project_id"], name: "index_datasources_on_project_id", using: :btree
  add_index "datasources", ["table_ref"], name: "index_datasources_on_table_ref", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "user_id"
  end

  add_index "projects", ["name"], name: "index_projects_on_name", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "datapackage_resource_fields", "datapackage_resources"
  add_foreign_key "datapackages", "projects"
  add_foreign_key "datasources", "projects"
end
