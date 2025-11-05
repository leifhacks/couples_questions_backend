#-------------------------------------------------------------------------------
# Worker class which performs a backup of the database
#-------------------------------------------------------------------------------
class DatabaseBackupWorker
  include Sidekiq::Worker

  def perform
    timestamp = DateTime.now.to_s.gsub('-', '').gsub('+', '').gsub(':', '')
    filename = "/mnt/backup/db-backup-#{timestamp}.gz"

    mysql_command = 'mysqldump --user=$MYSQL_ADMIN_NAME --password=$MYSQL_ADMIN_PASSWORD --all-databases'
    command = "#{mysql_command} | gzip -c > #{filename}"
    system(command)
  end
end
