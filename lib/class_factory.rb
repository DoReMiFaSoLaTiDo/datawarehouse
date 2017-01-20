module ClassFactory
  def create_class (klass, options={})

      Object.const_set(klass.classify, Class.new(DwhTable)  do
        def hello_class
          p "Class #{klass} created"
        end
      end
      )
  end
end