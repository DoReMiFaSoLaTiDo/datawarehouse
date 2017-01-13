class SalespeopleController < ApplicationController
  before_action :set_salesperson, only: [:show, :edit, :update, :destroy]

  # GET /salespeople
  # GET /salespeople.json
  def index
    @salespeople = Salesperson.all
  end

  # GET /salespeople/1
  # GET /salespeople/1.json
  def show
  end

  # GET /salespeople/new
  def new
    @salesperson = Salesperson.new
  end

  # GET /salespeople/1/edit
  def edit
  end

  # POST /salespeople
  # POST /salespeople.json
  def create
    @salesperson = Salesperson.new(salesperson_params)

    respond_to do |format|
      if @salesperson.save
        format.html { redirect_to @salesperson, notice: 'Salesperson was successfully created.' }
        format.json { render :show, status: :created, location: @salesperson }
      else
        format.html { render :new }
        format.json { render json: @salesperson.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /salespeople/1
  # PATCH/PUT /salespeople/1.json
  def update
    respond_to do |format|
      if @salesperson.update(salesperson_params)
        format.html { redirect_to @salesperson, notice: 'Salesperson was successfully updated.' }
        format.json { render :show, status: :ok, location: @salesperson }
      else
        format.html { render :edit }
        format.json { render json: @salesperson.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /salespeople/1
  # DELETE /salespeople/1.json
  def destroy
    @salesperson.destroy
    respond_to do |format|
      format.html { redirect_to salespeople_url, notice: 'Salesperson was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_salesperson
      @salesperson = Salesperson.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def salesperson_params
      params.require(:salesperson).permit(:name, :gender, :age, :height, :weight)
    end
end
