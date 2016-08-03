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

ActiveRecord::Schema.define(version: 20160803093245) do

  create_table "enhanced_genes", force: :cascade do |t|
    t.text     "gene_name"
    t.text     "data"
    t.text     "log"
    t.string   "strategy"
    t.boolean  "keep_first_intron"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "session_id"
  end

  create_table "enhancers", force: :cascade do |t|
    t.text     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "name"
    t.text     "exons"
    t.text     "introns"
    t.text     "gene_name"
    t.string   "session_id"
  end

  create_table "records", force: :cascade do |t|
    t.integer  "line"
    t.text     "data"
    t.integer  "enhancer_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "exons"
    t.text     "introns"
    t.text     "gene_name"
  end

  add_index "records", ["enhancer_id"], name: "index_records_on_enhancer_id"

end
