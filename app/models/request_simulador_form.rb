class RequestSimuladorForm
  include ActiveModel::Model

  attr_accessor :nome_do_curso, :nota_humanas, :nota_natureza, :nota_linguagens, :nota_matematica, :nota_redacao, :is_minority, :is_public_school, :has_low_income

  validates_presence_of :nota_humanas

  def save
    if valid?
      execute
      #true
    else
      false
    end
  end

  private

  def execute
    modalidades_de_concorrencia = get_modalidades_de_concorrencia(is_minority, is_public_school, has_low_income)
    nota_media = get_nota_media(nota_humanas, nota_natureza, nota_linguagens, nota_matematica, nota_redacao)
    ZndbxSisu.get_hash_universities_results(nome_do_curso, modalidades_de_concorrencia, nota_media)
  end

  def get_modalidades_de_concorrencia(is_minority, is_public_school, has_low_income)
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

  def get_nota_media(nota_humanas, nota_natureza, nota_linguagens, nota_matematica, nota_redacao)
    (nota_humanas + nota_natureza + nota_linguagens + nota_matematica + nota_redacao) / 5
  end

end