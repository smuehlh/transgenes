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

ActiveRecord::Schema.define(version: 20180105145619) do

  create_table "enhanced_genes", force: :cascade do |t|
    t.text     "gene_name"
    t.text     "data"
    t.text     "log"
    t.string   "strategy"
    t.boolean  "keep_first_intron"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "session_id"
    t.boolean  "destroy_ese_motifs"
    t.string   "select_by"
    t.text     "gene_variants"
    t.text     "gc3_over_all_gene_variants"
    t.boolean  "stay_in_subbox_for_6folds"
    t.string   "ese_strategy"
    t.boolean  "score_eses_at_all_sites"
    t.boolean  "keep_restriction_sites"
    t.boolean  "avoid_restriction_sites"
  end

  add_index "enhanced_genes", ["session_id"], name: "index_enhanced_genes_on_session_id"

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

  add_index "enhancers", ["session_id"], name: "index_enhancers_on_session_id"

  create_table "ensembl_genes", force: :cascade do |t|
    t.text     "cds"
    t.string   "gene_id"
    t.string   "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "utr5"
    t.text     "utr3"
  end

  add_index "ensembl_genes", ["gene_id"], name: "index_ensembl_genes_on_gene_id"

  create_table "eses", force: :cascade do |t|
    t.text     "data"
    t.string   "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "eses", ["session_id"], name: "index_eses_on_session_id"

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

  create_table "restriction_enzymes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "session_id"
    t.text     "data"
    t.string   "name"
  end

end
