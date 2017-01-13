# (Rails.application.eager_load!) && (ActiveRecord::Base.descendants.map {|klass| [klass.name, klass.count]})


desc 'Program to identify facts and dimensions table'
task :facts_identifier do
  # Generate all the models, their attributes, and reflections/references
  my_tabs = (Rails.application.eager_load!) && (ActiveRecord::Base.descendants.map {|klass| [klass.name, klass.column_names, klass.reflections.keys]})

# Preserve our originating data, and work with duplicate
  my_tabs2 = my_tabs.dup

# Create a new collection, and populate it with schema not in Level 1
  my_tabs3 = level1 = []

  my_tabs2.each { |e| e[2].size > 0 ? my_tabs3.push(e) : level1.push(3) }

  report(my_tabs3)

  def report(my_models=[])

    if my_models.size == 0
      puts "No star schema found after first operation"
    elsif my_models.size.eql?(1)
      puts "Star schema: Fact_Table: #{my_models[0]}"
    else
      puts "Continuing unto next operation: Disambiguation. Potential facts table: #{my_models.size}"

      results = disambiguate(my_models)

      # check if there are higher level models
      if results[1].size > 0
        report(results[1])
      else
        datatype_evaluation(results[0])
      end
    end


  end

  def disambiguate(options=[])
    # Collect medel names to see cross references
    # table_collection = options.map(&:first)
    table_collection = options.map{ |e| e[0].downcase}
    level2 = level3 = []
    options.each do |e|
      # Handle self-referencing tables like user models (follow/following)
      if e[2].include?e[0].downcase #(e[2] & table_collection).any? # Also handle self-reference over here
        spec_arr = e[2].dup
        spec_arr.delete(e[0].downcase)
        if (spec_arr & table_collection.any?)
          level3.push(e)
        else
          level2.push(e)
        end
      elsif (e[2] & table_collection).any?
        level3.push(e)
      else
        level2.push(e)
      end
    end

    return [level2, level3]
  end

  def datatype_evaluation(options=[])
    @my_biz = (Rails.application.eager_load!) && (ActiveRecord::Base.descendants.map {|klass| [klass.name, klass.column_names, klass.reflections.keys]})
  end
end
