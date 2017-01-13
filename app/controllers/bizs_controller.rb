class BizsController < ApplicationController
  before_action :set_biz, only: [:show, :edit, :update, :destroy]
  before_action :load_models, only: [:index, :new, :update_measures]
  # GET /bizs.js
  # GET /bizs.js.json
  def index
    @bizs = Biz.all
    # raise @my_biz.inspect
    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /bizs.js/1
  # GET /bizs.js/1.json
  def show
    @measure = @measures[params[:d_value]]
  end

  # GET /bizs.js/new
  def new
    @biz = Biz.new

    # raise @my_biz.inspect
  end

  # GET /bizs.js/1/edit
  def edit
  end

  # POST /bizs.js
  # POST /bizs.js.json
  def create
    @biz = Biz.new(biz_params)

    respond_to do |format|
      if @biz.save
        format.html { redirect_to @biz, notice: 'Biz was successfully created.' }
        format.json { render :show, status: :created, location: @biz }
        format.js
      else
        format.html { render :new }
        format.json { render json: @biz.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_measures
    # @biz = biz_params || Biz.new
    @measured = get_measures
    @measured.to_s
    respond_to do |format|
      format.js
    end
  end

  # PATCH/PUT /bizs.js/1
  # PATCH/PUT /bizs.js/1.json
  def update

    respond_to do |format|
      if @biz.update(biz_params)
        format.html { redirect_to @biz, notice: 'Biz was successfully updated.' }
        format.json { render :show, status: :ok, location: @biz }
      else
        format.html { render :edit }
        format.json { render json: @biz.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bizs.js/1
  # DELETE /bizs.js/1.json
  def destroy
    @biz.destroy
    respond_to do |format|
      format.html { redirect_to bizs_url, notice: 'Biz was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_biz
      @biz = Biz.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def biz_params
      # raise params.require(:biz).inspect
      params.require(:biz).permit(:fact, :dimension, :dimension_1, :dimension_2, :dimension_3, :dimension_4, :dimension_5, :measures_1, :measures_2, :measures_3, :measures_4, :measures_5 )
    end

    def load_models
      Rails.application.eager_load!
      @my_biz = ActiveRecord::Base.descendants #.map {|klass| [klass.name, klass.column_names, klass.reflections.keys]} #
      @dimensions = @my_biz.map.with_index {|klass, i| [ if i != 0; klass.name.constantize; else; end  ] }

      @measures = @my_biz.map {|klass| { klass.name.constantize => klass.column_names } }
      # @dimensions = @dimensions_arr.map{|i| i.id}
      @my_biz_subsections = @my_biz.each_with_index.map{ |klass, i| {name: klass.column_names, id: i} }


    end

    def get_measures
      my_idx = 1
      @dimensions.each_with_index do |e, i|
        my_idx = i if e.eql?(params[:d_value])
      end
      @measures.each do |k,v|
        return v if k.eql?(params[:d_value])
      end
    end


end
