class DwhEngine
  attr_accessor :biz

  def initialize(biz)
    @biz = biz
  end

  def create
    if self.biz.save
      self.create_relation
    end
  end

  def create_relation
    my_biz = Biz.find(@biz.id)
    if my_biz
      relation = {}
    #   build relation
      relation["fact"] = my_biz[:fact]
      relation["dimensions"] = my_biz[:dimensions]
      relation["job"] = 'create'
      # raise relation.inspect
      DwhWorker.perform_async(relation)
    end
  end

  # def update_relation
  #   my_biz = Biz.find(@biz.id)
  #   if my_biz
  #     relation = []
  #     #   build relation in this order [fact, *dimension]
  #     relation.push(my_biz[:fact]).push(my_biz[:dimensions]).flatten!
  #     DwhWorker.perform_async(relation,'update')
  #   end
  # end

  def update_record

  end
end

