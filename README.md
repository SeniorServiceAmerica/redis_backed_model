# RedisBackedModel

Provides useful functions to objects that are backed by a Redis store instead of ActiveRecord.

## Installation

Add this line to your application's Gemfile:

    gem 'redis_backed_model'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_backed_model

## Testing

You need a Redis server running. Follow the [redis instructions](http://redis.io/download) for installation and then start the server with `redis-server`. Then test with `bundle exec rake`.

## Usage

Subclass your models from RedisBackedModel::RedisBackedModel

```ruby
  class Person < RedisBackedModel::RedisBackedModel
  end
```

When initializing a person, pass in a hash of attributes

```ruby
  p = Person.new({:id => 2, :first_name => "Bill", :last_name => "Smith"})
```

RBM will create instance variables as needed

```ruby
  p.instance_variables => [:@id, :@first_name, :@last_name]
```

You can use RBM to get Redis commands that will save your object as a hash

```ruby
  p.to_redis => ["sadd|person_ids|2", "hset|person:2|id|2", "hset|person:2|first_name|Bill", "hset|person:2|last_name|Smith"]
```

If the value of a variable is nil, it is not included in the to_redis commands

```ruby
  p = Person.new({:id => 2, :first_name => "Bill", :last_name => nil})
  p.to_redis => ["sadd|person_ids|2", "hset|person:2|id|2", "hset|person:2|first_name|Bill"]
```

You can parse the to_redis results and pass them to Redis yourself or use the gem 'redis_pipeline': https://github.com/SeniorServiceAmerica/redis_pipeline

Once your data is in Redis, you can use RBM to find and instantiate objects:

```ruby
  p = Person.find(2) => #<Person:0x00000104023a00 @id=2, @first_name=Bill, @last_name=Smith>
```

You can also find multiple records:

```ruby
  p = Person.find([1,2,3]) => [person,person,person]
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
