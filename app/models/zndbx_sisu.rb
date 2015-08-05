require 'concerns/importable'
require 'csv'

class ZndbxSisu < ActiveRecord::Base
	include Importable

  def accessible_attributes
    ["nome_da_ies", "sigla", "local_de_oferta", "codigo_do_curso", "nome_do_curso", "grau", "turno", "modalidade_de_concorrencia", "nota_de_corte"]
  end

  def self.filter_by_nome_do_curso(nome_do_curso)
    where("nome_do_curso=?", nome_do_curso)
  end

  def self.filter_by_modalidade_de_concorrencia(modalidade_de_concorrencia)
    where("modalidade_de_concorrencia=?", modalidade_de_concorrencia)
  end

  def self.get_output_simulador_enem(nome_do_curso, modalidade_de_concorrencia, nota_media)

  end
end
