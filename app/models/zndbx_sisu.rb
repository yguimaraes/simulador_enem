require 'concerns/importable'
require 'csv'

class ZndbxSisu < ActiveRecord::Base
  include Importable

  def self.accessible_attributes
    ["nome_da_ies", "sigla", "local_de_oferta", "codigo_do_curso", "nome_do_curso", "grau", "turno", "modalidade_de_concorrencia", "nota_de_corte"]
  end

  def self.get_cursos
    pluck(:nome_do_curso).uniq.sort
  end

  def self.get_hash_universities_results(nome_do_curso, modalidades_de_concorrencia, nota_media_aluno)
    query_universities = filter_request_aluno(nome_do_curso, modalidades_de_concorrencia)
    #universities_approved = get_universities_approved(query_universities, nota_media_aluno)
    #universities_reproved = get_universities_reproved(query_universities, nota_media_aluno)
    universities_approved = get_universities_by_score_range(query_universities, 0, nota_media_aluno, false)
    universities_almost_approved = get_universities_by_score_range(query_universities, nota_media_aluno, nota_media_aluno + almost_value)
    universities_reproved = get_universities_by_score_range(query_universities, nota_media_aluno + almost_value, 1000)
    { universities_approved: universities_approved, universities_almost_approved: universities_almost_approved, universities_reproved:universities_reproved }
  end

  private

  def self.almost_value
    50
  end

  def self.filter_request_aluno(nome_do_curso, modalidades_de_concorrencia)
    # select the entries that offers the course the student wants, picking just the one with the minimum mark requirement he needs based on the modalities he participates.

    ZndbxSisu.select('MIN(nota_de_corte) as nota_de_corte, nome_do_curso, nome_da_ies, local_de_oferta, sigla, turno, modalidade_de_concorrencia')
        .where(modalidade_de_concorrencia: modalidades_de_concorrencia)
        .where(nome_do_curso: nome_do_curso)
        .group('nome_do_curso, nome_da_ies, local_de_oferta, turno')

    #sql = "SELECT * FROM zndbx_sisus AS rowSisu WHERE nome_do_curso = '#{nome_do_curso}' AND nota_de_corte = (SELECT MIN(nota_de_corte) FROM zndbx_sisus WHERE sigla = rowSisu.sigla AND local_de_oferta = rowSisu.local_de_oferta AND turno = rowSisu.turno AND nome_do_curso = '#{nome_do_curso}' AND modalidade_de_concorrencia IN ('#{modalidade_de_concorrencia.first}'))"
    #ActiveRecord::Base.connection.execute(sql)
  end

  def self. get_universities_by_score_range(query_universities, min_score, max_score, isAsc = true)
    if(isAsc)
      query_universities.having("nota_de_corte > ? AND nota_de_corte <= ?", min_score, max_score).order(:nota_de_corte).to_a
    else
      query_universities.having("nota_de_corte > ? AND nota_de_corte <= ?", min_score, max_score).order(nota_de_corte: :desc).to_a
    end
  end

  def self.get_universities_approved(query_universities, nota_media_aluno)
    #query_universities.having("nota_de_corte <= ?", nota_media_aluno).order(nota_de_corte: :desc).to_a
  end

  def self.get_universities_reproved(query_universities, nota_media_aluno)
    query_universities.having("nota_de_corte > ?", nota_media_aluno).order(:nota_de_corte).to_a
    #array_universities.select { |row| row[:nota_de_corte] > nota_media_aluno }.sort { |x,y| x[:nota_de_corte] <=> y[:nota_de_corte]}
  end

end
