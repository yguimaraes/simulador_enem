class RequestSimulador
  include ActiveModel::Model

  attr_accessor :nome_do_curso, :nota_humanas, :nota_natureza, :nota_linguagens, :nota_matematica, :nota_redacao, :is_minority, :is_public_school, :has_low_income
end