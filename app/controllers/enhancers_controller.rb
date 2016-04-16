class EnhancersController < ApplicationController
  before_action :set_enhancer, only: [:show, :edit, :update, :destroy]

  # GET /enhancers
  # GET /enhancers.json
  def index
    @enhancers = Enhancer.all
  end

  # GET /enhancers/1
  # GET /enhancers/1.json
  def show
  end

  # GET /enhancers/new
  def new
    @enhancer = Enhancer.new
  end

  # GET /enhancers/1/edit
  def edit
  end

  # POST /enhancers
  # POST /enhancers.json
  def create
    @enhancer = Enhancer.new(enhancer_params)

    respond_to do |format|
      if @enhancer.save
        format.html { redirect_to @enhancer, notice: 'Enhancer was successfully created.' }
        format.json { render :show, status: :created, location: @enhancer }
      else
        format.html { render :new }
        format.json { render json: @enhancer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /enhancers/1
  # PATCH/PUT /enhancers/1.json
  def update
    respond_to do |format|
      if @enhancer.update(enhancer_params)
        format.html { redirect_to @enhancer, notice: 'Enhancer was successfully updated.' }
        format.json { render :show, status: :ok, location: @enhancer }
      else
        format.html { render :edit }
        format.json { render json: @enhancer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /enhancers/1
  # DELETE /enhancers/1.json
  def destroy
    @enhancer.destroy
    respond_to do |format|
      format.html { redirect_to enhancers_url, notice: 'Enhancer was successfully destroyed.' }
      format.json { head :no_content }
    end
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
