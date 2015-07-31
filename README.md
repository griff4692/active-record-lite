# active-record-lite

# Summary description

- Active Record Lite is an interface between Rails and SQL inspired by Rails' Active Record.
- It leverages Ruby's metaprogramming functionality to create a fully extendable SQLObject class which supports all the functionality provided by ActiveRecord::Base.
- Specifically, the SQLObject class provides getter and setter methods, search capability, and methods for both direct and indirect associations.

# How to Use:
- Simply extend the class SQLObject and call self.finalize! in the model's constructor
- If you want a custom table name (as opposed to the pluralized default snake cased version), use the setter instance method #table_name to customize
- Your model class will now have access to the following methods:
  - factory methods: #find(id), #where(params), #columns
  - instance methods: #attribute_values, #update, #save
  - instance associations: #belongs_to(options), #has_many(options), #has_one_through(name, through, source), #has_many_through(name, through, source)

# Features:
- Full test suite using RSpec
- Conventional default values for model associations
- Association options are stored in a hash which enables the creation of deep associations
- Frequent use of Heredocs to built up SQL strings in Ruby

# Features to Add:

- Creation of validator methods / validator class
- An includes method that does pre-fetching
- A joins method
