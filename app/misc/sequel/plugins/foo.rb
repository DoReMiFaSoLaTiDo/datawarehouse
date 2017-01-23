module Sequel::Plugin::Foo
  def self.apply(model)
    model.plugin :timestamps, :create => :created_on, :update => :updated_on
    model.plugin :validation_helpers
    model.many_to_one :user
  end

  module InstanceMethods
    # Note that it's probably a bad idea to override initialize unless you
    # really know what you are doing.
    def initialize(params={})

    end

    # Make sure to call super inside these methods.
    def before_save
      super
    end
    def after_create
      super
    end
    def validate
      super
    end
  end
end