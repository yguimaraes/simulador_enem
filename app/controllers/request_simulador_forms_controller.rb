class RequestSimuladorFormsController < ApplicationController

  def new
    @request_simulador_form = RequestSimuladorForm.new
  end

  def create
    @request_simulador_form = RequestSimuladorForm.new(request_simulador_form_params)

    if @hash_universities = @request_simulador_form.save
      render :create
    else
      render :new
    end
  end

  private

  def request_simulador_form_params
    params.require(:request_simulador_form).permit(:nome_do_curso, :nota_humanas, :nota_natureza, :nota_linguagens, :nota_matematica, :nota_redacao, :is_minority, :is_public_school, :has_low_income)
  end

end
