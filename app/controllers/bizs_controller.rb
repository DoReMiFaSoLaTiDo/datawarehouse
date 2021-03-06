class BizsController < ApplicationController
  before_action :set_biz, only: [:show, :edit, :update, :destroy]
  before_action :load_models #, only: [:index, :new, :update_measures, :show, :edit, :create, :get_dimensions, :update_dimensions, :new_factors, :collect_dimensions_measures ]

  before_filter :collect_dimensions_measures, only: [:create, :update]
  # GET /bizs.js
  # GET /bizs.js.json
  def index
    @bizs = Biz.all
    @count = 0
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

  end

  # GET /bizs.js/1/edit
  def edit

    @count = @biz.dimensions.size
    @dimensions = @potential_facts.to_h[@biz.fact].map{|dim| [dim.to_s.capitalize]}

    dimension_arr = []
    dimension_arr.push(@biz.fact).push(@biz.dimensions)
    @dimens = new_dimensions_html(dimension_arr)
    (0..@count-1).each do |num|
      @biz["measures"][num] = @biz["measures"][num].tr('^a-z,-',"").split(',') if @biz["measures"][num]
    end

    @dims = @dimens.map{|dim| [dim.to_s.capitalize]}

  end


  # POST /bizs.js
  # POST /bizs.js.json
  def create

    @biz = Biz.new(biz_params)
    respond_to do |format|
      if @biz.save
        # DwhEngine.new(@biz).create_relation
        if params[:add_dimension]

          format.html { redirect_to edit_biz_path(@biz)}
        else
          relation = {}
          #   build relation
          relation['fact'] = @biz[:fact]
          relation["dimensions"] = @biz[:dimensions]
          relation["id"] = @biz[:id]
          relation["attribs"] = {}
          @biz[:dimensions].each_with_index do |bd, idx|
            relation['attribs'][bd] = @biz["measures"][idx].tr('^a-z,-',"").split(',') if @biz["measures"][idx]
          end
          relation["job"] = 'create'
          # raise relation.inspect
          DwhWorker.perform_async(relation)

          format.html { redirect_to @biz, notice: 'Biz was successfully created.' }
          format.json { render :show, status: :created, location: @biz }
          format.js
        end
      else
        format.html { render :new }
        format.json { render json: @biz.errors, status: :unprocessable_entity }
      end
    end
  end


  def update_measures
    @measures = get_measures
    # raise @measures.inspect
    @msrs = @measures.map.with_index {|msr, idx| [msr,idx]} if @measures
    respond_to do |format|
      format.js
    end
  end

  def get_dimensions
    @dimens = my_dimensions
    # raise @dimens.inspect
    @dims = @dimens.map{|dim, idx| [dim.to_s.capitalize,idx]}
    respond_to do |format|
      format.js
    end
  end

  def update_dimensions
    @dimens = new_dimensions
    @dimensions = @dimens.map{|dim, idx| [dim.to_s.capitalize,idx]}
    respond_to do |format|
      # format.html
      format.js
    end
  end

  def synchronize
    DwhJobs.find_and_update_records(params[:job])
  end

  def new_factors
    @dimens = new_dimensions
    # raise @dimens.inspect
    @count += 1
    @dims = @dimens.map{|dim, idx| [dim.to_s.capitalize,idx]}
    respond_to do |format|
      format.js
    end
  end
  # PATCH/PUT /bizs.js/1
  # PATCH/PUT /bizs.js/1.json
  def update

    respond_to do |format|
      if @biz.update(biz_params)
        if params[:add_dimension]
          format.html { redirect_to edit_biz_path(@biz)}

        else
          relation = {}
          relation['fact'] = @biz[:fact]
          relation["dimensions"] = @biz[:dimensions]
          relation["id"] = @biz[:id]
          relation["attribs"] = {}
          @biz[:dimensions].each_with_index do |bd, idx|
            relation['attribs'][bd] = @biz["measures"][idx].tr('^a-z,-_',"").split(',') if @biz["measures"][idx]
          end
          relation["job"] = 'create'
          # raise relation.inspect
          DwhWorker.perform_async(relation)
        format.html { redirect_to @biz, notice: 'Biz was successfully updated.' }
        format.json { render :show, status: :ok, location: @biz }
        end
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
      permitted_params = params.require(:biz).permit!
    end

    def load_models
      Rails.application.eager_load!
      @my_biz = ActiveRecord::Base.descendants #.map {|klass| [klass.name, klass.column_names, klass.reflections.keys]} #
      # raise @my_biz.inspect
      # @model_array = @my_biz.map{|klass| [klass.name, klass.column_names, klass.reflections.keys]}
      @my_facts = @my_biz.map{|klass| [klass.name] }
      @model_array = @my_biz.map{|klass| [klass.name, klass.column_names, klass.reflections.keys]}
      @my_factors = @my_biz.map{|klass| [klass.name, klass.reflect_on_all_associations.map{|klazz| klazz.name}] }
      @potential_facts = @my_factors.select{|kl| kl if kl[1].present?}
      @dimensions = @my_biz.map.with_index {|klass, i| [ if i != 0; klass.name.constantize; else; end  ] }
      @default_measures = []
      @msrs_sym = @my_biz.map {|klass| [ klass.name.downcase.to_sym, klass.column_names ] }
      @my_biz_subsections = @my_biz.each_with_index.map{ |klass, i| {name: klass.column_names, id: i} }
      @count = 0
      @msrs_str = @my_biz.map {|klass| [ klass.name, klass.column_names ] }

      @msrs_hash = Hash[@msrs_sym]
      @updated_msrs = {}
      @my_factors.each_with_index  do |dm, idx|
        next if idx == 0
        fd = dm.flatten.map(&:downcase).map(&:to_sym)

        @updated_msrs[fd[0]] = []
        fd.each do |f|
          @updated_msrs[fd[0]].push(prepend_values(@msrs_hash[f], f.to_s)) if @msrs_hash[f]
        end
        @updated_msrs[fd[0]].flatten!
        @updated_msrs[fd[0]].uniq!
      end

    end

    def prepend_values(attribs,model_klass)
      attribs.map{ |attrib| model_klass + "-" + attrib }
    end

    def get_measures

      return_value = @updated_msrs[params[:d_value].downcase.to_sym]
    end

  def get_measures_old
    # raise params[:d_value].inspect
    return_value = []
    @msrs_sym.each do |msr|
      return_value.push( msr[1]) if msr[0].eql?( params[:d_value].downcase.to_sym ) #if msr.key.eql?(params[:d_value].downcase.to_sym)
    end
    return return_value.flatten!
  end

    def my_dimensions

      @potential_facts.to_h[params[:f_value]]

    end

    # returns new set of dimensions based on previous selections
    def new_dimensions_html(dimension_arr)
      applicable_dimensions = @potential_facts.to_h[dimension_arr[0]]
      selected_dimensions = dimension_arr[1..-1].flatten.map(&:downcase).map(&:to_sym)
      app_dimens = applicable_dimensions - selected_dimensions

    end

    # same as new_dimensions_html, but this is for js
    def new_dimensions
      applicable_dimensions = @potential_facts.to_h[params[:a_value][0]]
      selected_dimensions = params[:a_value][1..-1].map(&:downcase).map(&:to_sym)
      app_dimens = applicable_dimensions - selected_dimensions

    end

    def collect_dimensions_measures
      # raise params.inspect

      params.tap do |bp|
        bp["biz"][:measures] = []
        bp["biz"][:dimensions]= []

        (0..@model_array.size-1).each do |col|
          if bp["biz"]["dimensions_#{col}"].present?
            bp["biz"][:dimensions].push(bp["biz"]["dimensions_#{col}"])
            bp["biz"].delete("dimensions_#{col}")
            bp["biz"][:measures].push bp["biz"]["measures_"]["#{col}"].join(', ') if bp["biz"]["measures_"]["#{col}"].present?
          else
            bp["biz"].delete("dimensions_#{col}")
          end
        end
        bp["biz"].delete("measures_")
      end
    end

end
