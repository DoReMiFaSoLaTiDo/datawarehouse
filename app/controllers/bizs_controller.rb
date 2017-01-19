class BizsController < ApplicationController
  before_action :set_biz, only: [:show, :edit, :update, :destroy]
  before_action :load_models, only: [:index, :new, :update_measures, :show, :edit, :create]

  before_filter :collect_dimensions_measures, only: [:create, :update]
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
    @biz.tap {|bz| bz.dimensions.to_a }

  end

  # GET /bizs.js/new
  def new
    @biz = Biz.new
    # raise @biz.inspect
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
    @measures = get_measures
    @msrs = @measures.map.with_index {|msr, idx| [msr,idx]}
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
      # my_dimensions = []
      # (0..@my_biz.size-1).each {|myb| my_dimensions.push("measures_[#{myb}]") }

      permitted_params = params.require(:biz).permit!
    end

    def load_models
      Rails.application.eager_load!
      @my_biz = ActiveRecord::Base.descendants #.map {|klass| [klass.name, klass.column_names, klass.reflections.keys]} #
      @my_facts = @my_biz.map{|klass| [klass.name] }
      @dimensions = @my_biz.map.with_index {|klass, i| [ if i != 0; klass.name.constantize; else; end  ] }
      @default_measures = []
      @msrs_sym = @my_biz.map {|klass| [ klass.name.downcase.to_sym, klass.column_names ] }
      @my_biz_subsections = @my_biz.each_with_index.map{ |klass, i| {name: klass.column_names, id: i} }

    end

    def get_measures

      return_value = []
      @msrs_sym.each do |msr|
        return_value.push( msr[1]) if msr[0].eql?( params[:d_value].downcase.to_sym ) #if msr.key.eql?(params[:d_value].downcase.to_sym)
      end
       return return_value.flatten!
    end

    def collect_dimensions_measures

      params.tap do |bp|
        bp["biz"][:measures] = []
        bp["biz"][:dimensions]= []
        # bp[:measures] = bp[:measures_].to_a
        (0..@my_biz.size-1).each do |col|
          if bp["biz"]["dimensions_#{col}"].present?
            bp["biz"][:dimensions].push(bp["biz"]["dimensions_#{col}"])
            bp["biz"].delete("dimensions_#{col}")
            bp["biz"][:measures].push bp["biz"]["measures_"]["#{col}"].to_s
          else
            bp["biz"].delete("dimensions_#{col}")
          end
        end
        bp["biz"].delete("measures_")
      end
    end
end
