# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Initial Migration
#-------------------------------------------------------------------------------
class Initial < ActiveRecord::Migration[6.0]
  def change
    create_table 'api_keys', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'access_token'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end

    create_table 'client_devices', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'device_token', null: false
      t.string 'iso_code', null: false
      t.text 'last_response'
      t.timestamp 'last_access'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
      t.belongs_to :user, null: false
      t.belongs_to :web_socket_connection
    end

    create_table 'push_notifications', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.integer 'hours'
      t.integer 'minutes'
      t.string 'notification_type'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
      t.belongs_to :user, null: false
    end

    create_table 'users', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'identifier', index: { unique: true }, null: false
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end

    create_table 'web_socket_connections', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end
  end
end
