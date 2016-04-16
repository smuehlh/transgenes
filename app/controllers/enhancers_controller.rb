class EnhancersController < ApplicationController
  before_action :set_enhancer, only: [:show, :edit, :update, :destroy]

  def index
    Enhancer.delete_all
    init_gene_enhancers
    @enhancers = Enhancer.all
    @enhancer = Enhancer.new
  end

  def create
    @enhancers = Enhancer.all
    # only single object with given name is allowed.
    enhancer = Enhancer.where(name: enhancer_params[:name]).first
    enhancer.destroy if enhancer
    @enhancer = Enhancer.create(enhancer_params)
  end

  private
    def init_gene_enhancers
        Enhancer.create(name: "5'UTR")
        Enhancer.create(name: "CDS")
        Enhancer.create(name: "3'UTR")
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_enhancer
      @enhancer = Enhancer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def enhancer_params
      params.require(:enhancer).permit(:data, :name)
    end
end
