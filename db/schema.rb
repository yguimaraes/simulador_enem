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

ActiveRecord::Schema.define(version: 20150803222136) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "zndbx_sisus", force: :cascade do |t|
    t.string   "nome_da_ies"
    t.string   "sigla"
    t.string   "local_de_oferta"
    t.integer  "codigo_do_curso",            limit: 8
    t.string   "nome_do_curso"
    t.string   "grau"
    t.string   "turno"
    t.text     "modalidade_de_concorrencia"
    t.float    "nota_de_corte"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  add_index "zndbx_sisus", ["modalidade_de_concorrencia"], name: "index_zndbx_sisus_on_modalidade_de_concorrencia", using: :btree
  add_index "zndbx_sisus", ["nome_do_curso"], name: "index_zndbx_sisus_on_nome_do_curso", using: :btree

end
