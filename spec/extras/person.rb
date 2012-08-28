class Person < RedisBackedModel::RedisBackedModel
  attr_reader :id, :first_name, :last_name
  
  def self.all
    all = []
    ids.each do |id|
      all << self.find(id)
    end
    all
  end

  #def self.first
    #id = ids.first
    #self.find(id)
  #end
  
  def self.find(id)
    attr = $redis.hgetall("person:#{id}")
    self.new(attr.merge({'id' => id}))
  end

  #def self.last
    #id = ids.last
    #self.find(id)
  #end

  def self.to_csv
    f = File.new("person.csv", "w+")
    f << "id,first_name,last_name\n"
    self.all.each do |x|
      f << "#{x.id},#{x.first_name},#{x.last_name}\n"
    end
  end

  # def initialize(attr)
    # @id = attr[:id]
    # @first_name = attr["first_name"]
    # @last_name = attr["last_name"]
  # end

  def name
    "#{self.first_name} #{self.last_name}"
  end

  private

  def self.ids
    @ids ||= $redis.sort('person_ids')
  end
end
