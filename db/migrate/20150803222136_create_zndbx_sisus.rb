class CreateZndbxSisus < ActiveRecord::Migration
  def change
    create_table :zndbx_sisus do |t|
      t.string :nome_da_ies
      t.string :sigla
      t.string :local_de_oferta
      t.bigint :codigo_do_curso
      t.string :nome_do_curso
      t.string :grau
      t.string :turno
      t.text :modalidade_de_concorrencia
      t.float :nota_de_corte

      t.timestamps null: false
    end

    add_index :zndbx_sisus, :nome_do_curso
    add_index :zndbx_sisus, :modalidade_de_concorrencia
  end
end
