require 'concerns/importable'
require 'csv'

class ZndbxSisu < ActiveRecord::Base
  include Importable

  def self.accessible_attributes
    ["nome_da_ies", "sigla", "local_de_oferta", "codigo_do_curso", "nome_do_curso", "grau", "turno", "modalidade_de_concorrencia", "nota_de_corte"]
  end

  def self.get_cursos
    pluck(:nome_do_curso).uniq
  end

  def self.filter_request_aluno(nome_do_curso, modalidade_de_concorrencia)
    # select the entries that offers the course the student wants, picking just the one with the minimum mark requirement he needs based on the modalities he participates.

    ZndbxSisu.select('MIN(nota_de_corte) as nota_de_corte, nome_do_curso, nome_da_ies, local_de_oferta, sigla, turno, modalidade_de_concorrencia')
             .where(modalidade_de_concorrencia: modalidade_de_concorrencia)
             .where(nome_do_curso: nome_do_curso)
             .group('nome_do_curso, nome_da_ies, local_de_oferta, turno')

    #sql = "SELECT * FROM zndbx_sisus AS rowSisu WHERE nome_do_curso = '#{nome_do_curso}' AND nota_de_corte = (SELECT MIN(nota_de_corte) FROM zndbx_sisus WHERE sigla = rowSisu.sigla AND local_de_oferta = rowSisu.local_de_oferta AND turno = rowSisu.turno AND nome_do_curso = '#{nome_do_curso}' AND modalidade_de_concorrencia IN ('#{modalidade_de_concorrencia.first}'))"
    #ActiveRecord::Base.connection.execute(sql)
  end

  def self.get_hash_universities_results(nome_do_curso, modalidade_de_concorrencia, nota_media_aluno)
    query_universities = filter_request_aluno(nome_do_curso, modalidade_de_concorrencia)
    universities_approved = get_universities_approved(query_universities, nota_media_aluno)
    universities_reproved = get_universities_reproved(query_universities, nota_media_aluno)
    { universities_approved: universities_approved, universities_reproved:universities_reproved }
  end

  def self.get_universities_approved(array_universities, nota_media_aluno)
    query_universities.where("nota_de_corte <= ?", nota_media_aluno).order(:nota_de_corte).to_a
  end

  def self.get_universities_reproved(array_universities, nota_media_aluno)
    query_universities.where("nota_de_corte > ?", nota_media_aluno).order(:nota_de_corte).to_a
    #array_universities.select { |row| row[:nota_de_corte] > nota_media_aluno }.sort { |x,y| x[:nota_de_corte] <=> y[:nota_de_corte]}
  end

  def self.get_nota_media(nota_humanas, nota_natureza, nota_linguagens, nota_matematica, nota_redacao)
    (nota_humanas + nota_natureza + nota_linguagens + nota_matematica + nota_redacao) / 5
  end

  def self.get_modalidades_de_concorrencia(is_minority, is_public_school, has_low_income)
    modalidades_de_concorrencia = ["Ampla Concorrência"]
    if(is_minority && is_public_school)
      modalidades_de_concorrencia << "Candidatos autodeclarados pretos, pardos ou indígenas que, independentemente da renda (art. 14, II, Portaria Normativa nº 18/2012), tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
      modalidades_de_concorrencia << "Candidatos autodeclarados indígenas que, independentemente da renda (art. 14, II, Portaria Normativa nº 18/2012), tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
      modalidades_de_concorrencia << "Candidatos autodeclarados pretos ou pardos que, independentemente da renda (art. 14, II, Portaria Normativa nº 18/2012), tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
    end
    if(is_public_school)
      modalidades_de_concorrencia << "Candidatos que, independentemente da renda (art. 14, II, Portaria Normativa nº 18/2012), tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
    end
    if(is_minority && is_public_school && has_low_income)
      modalidades_de_concorrencia << "Candidatos autodeclarados pretos, pardos ou indígenas, com renda familiar bruta per capita igual ou inferior a 1,5 salário mínimo e que tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
      modalidades_de_concorrencia << "Candidatos autodeclarados indígenas, com renda familiar bruta per capita igual ou inferior a 1,5 salário mínimo e  que tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
      modalidades_de_concorrencia << "Candidatos autodeclarados pretos ou pardos, com renda familiar bruta per capita igual ou inferior a 1,5 salário mínimo que tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
    end
    if(is_public_school && has_low_income)
      modalidades_de_concorrencia << "Candidatos com renda familiar bruta per capita igual ou inferior a 1,5 salário mínimo que tenham cursado integralmente o ensino médio em escolas públicas (Lei nº 12.711/2012)."
    end
    modalidades_de_concorrencia
  end

end
