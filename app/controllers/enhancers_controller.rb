class EnhancersController < ApplicationController
  before_action :set_enhancer, only: [:show, :edit, :update, :destroy]

  def index
    @enhancers = Enhancer.all
  end

  def show
    @enhancer = Enhancer.find(params[:id])
  end

  def new
    @enhancer = Enhancer.new
  end

  def create
    @enhancers = Enhancer.all
    @enhancer = Enhancer.create(enhancer_params)
  end

  def edit
    @enhancer = Enhancer.find(params[:id])
  end

  def update
    @enhancers = Enhancer.all
    @enhancer = Enhancer.find(params[:id])

    @enhancer.update_attributes(enhancer_params)
  end

  def delete
    @enhancer = Enhancer.find(params[:enhancer_id])
  end

  def destroy
    @enhancers = Enhancer.all
    @enhancer = Enhancer.find(params[:id])
    @enhancer.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_enhancer
      @enhancer = Enhancer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def enhancer_params
      params.require(:enhancer).permit(:data)
    end
end
