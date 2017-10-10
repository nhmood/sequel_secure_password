require 'rubygems'
require 'bundler'
Bundler.setup

require 'sequel'
require 'sequel/extensions/migration'
require 'sequel/plugins/secure_password'


RSpec.configure do |c|
  c.before :suite do

    # Based on the Ruby Engine, connect to the specified in memory SQLite db
    Sequel::Model.db = begin
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
        require 'jdbc/sqlite3'
        Sequel.connect("jdbc:sqlite::memory:")
      else
        require 'sqlite3'
        Sequel.sqlite(":memory:")
      end # if defined?
    end # Sequel::Model.db =


    # Create the Sequel migration to populate the necessary user tables
    migration = Sequel.migration do
      up do
        create_table(:users) do
          primary_key :id
          varchar     :password_digest
        end # create_table(:users)

        create_table(:high_cost_users) do
          primary_key :id
          varchar     :password_digest
        end # create_table(:high_cost_users)

        create_table(:user_without_validations) do
          primary_key :id
          varchar     :password_digest
        end # create_table(:high_cost_users)

        create_table(:user_with_alternate_digest_columns) do
          primary_key :id
          varchar     :password_hash
        end # create_table(:high_cost_users)
      end # up do
    end # Sequel.migration

    # Apply the migration against the SQLite in memory db we established earlier
    migration.apply(Sequel::Model.db, :up)

    # Configure the Sequel Models with various secure_password options
    class User < Sequel::Model
      plugin :secure_password
    end

    class HighCostUser < Sequel::Model
      plugin :secure_password, cost: 12
    end

    class UserWithoutValidations < Sequel::Model
      plugin :secure_password, include_validations: false
    end

    class UserWithAlternateDigestColumn < Sequel::Model
      plugin :secure_password, digest_column: :password_hash
    end
  end

  c.around :each do |example|
    Sequel::Model.db.transaction(:rollback => :always) { example.run }
  end
end
