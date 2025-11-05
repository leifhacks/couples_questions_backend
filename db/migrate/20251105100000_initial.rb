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
    add_index 'api_keys', ['access_token'], unique: true, name: 'idx_api_keys_unique_access_token'

    create_table 'client_devices', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.string 'device_token', null: false
      t.string 'platform'
      t.string 'iso_code', null: false
      t.string 'timezone_name'
      t.integer 'timezone_offset_seconds'
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
      t.string 'uuid', index: { unique: true }, null: false
      t.string 'name'
      t.string 'image_path'
      t.string 'auth_type', default: 'anonymous', null: false
      t.bigint 'current_relationship_id'
      t.bigint 'favorite_category_id'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end

    create_table 'relationships', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.string 'status', default: 'PENDING', null: false
      t.string 'distance'
      t.string 'relationship_type'
      t.string 'timezone_name'
      t.integer 'timezone_offset_seconds'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end

    create_table 'relationship_memberships', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.belongs_to :relationship, null: false
      t.belongs_to :user, null: false
      t.string 'role'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end
    add_index 'relationship_memberships', ['relationship_id', 'user_id'], unique: true, name: 'idx_relationship_memberships_unique_pair'

    create_table 'invite_codes', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.belongs_to :relationship, null: false
      t.string 'code', null: false
      t.bigint 'created_by_user_id', null: false
      t.datetime 'expires_at'
      t.datetime 'used_at'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end
    add_index 'invite_codes', ['code'], unique: true, name: 'idx_invite_codes_unique_code'

    create_table 'categories', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.string 'name_en'
      t.string 'name_de'
      t.text 'description_en'
      t.text 'description_de'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end

    create_table 'questions', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.text 'body_en'
      t.text 'body_de'
      t.boolean 'is_active', default: true, null: false
      t.integer 'depth_level'
      t.belongs_to :category, null: false
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end

    create_table 'question_assignments', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.belongs_to :relationship, null: false
      t.belongs_to :question, null: false
      t.date 'question_date', null: false
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end
    add_index 'question_assignments', ['relationship_id', 'question_date'], unique: true, name: 'idx_question_assignments_unique_rel_date'

    create_table 'answers', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.text 'body'
      t.belongs_to :question_assignment, null: false
      t.belongs_to :user, null: false
      t.string 'reaction'
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end
    add_index 'answers', ['question_assignment_id', 'user_id'], unique: true, name: 'idx_answers_unique_per_assignment_user'

    create_table 'user_sessions', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.belongs_to :user, null: false
      t.string 'refresh_token_hash', null: false
      t.datetime 'expires_at', null: false
      t.boolean 'active', default: true, null: false
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end
    add_index 'user_sessions', ['refresh_token_hash'], unique: true, name: 'idx_user_sessions_unique_refresh_hash'

    create_table 'web_socket_connections', options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8mb4', force: :cascade do |t|
      t.string 'uuid', index: { unique: true }, null: false
      t.datetime 'created_at', precision: 6, null: false
      t.datetime 'updated_at', precision: 6, null: false
    end

    #--------------------------------------------------------------------------
    # Foreign Keys
    #--------------------------------------------------------------------------
    add_index 'users', ['current_relationship_id'], name: 'idx_users_current_relationship_id'
    add_index 'users', ['favorite_category_id'], name: 'idx_users_favorite_category_id'

    add_foreign_key 'users', 'relationships', column: 'current_relationship_id'
    add_foreign_key 'users', 'categories', column: 'favorite_category_id'

    add_foreign_key 'relationship_memberships', 'relationships'
    add_foreign_key 'relationship_memberships', 'users'

    add_foreign_key 'invite_codes', 'relationships'
    add_foreign_key 'invite_codes', 'users', column: 'created_by_user_id'

    add_foreign_key 'questions', 'categories'

    add_foreign_key 'question_assignments', 'relationships'
    add_foreign_key 'question_assignments', 'questions'

    add_foreign_key 'answers', 'question_assignments'
    add_foreign_key 'answers', 'users'

    add_foreign_key 'client_devices', 'users'
    add_foreign_key 'client_devices', 'web_socket_connections'

    add_foreign_key 'push_notifications', 'users'

    add_foreign_key 'user_sessions', 'users'
  end
end
