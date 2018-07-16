require 'whenever'

# Learn more: http://github.com/javan/whenever

app_config = YAML.load_file(File.join(__dir__, 'application.yml'))

env "MAILTO", app_config["SCHEDULE_NOTIFICATIONS"] if app_config["SCHEDULE_NOTIFICATIONS"]

# If we use -e with a file containing specs, rspec interprets it and filters out our examples
job_type :run_file, "cd :path; :environment_variable=:environment bundle exec script/rails runner :task :output"
job_type :enqueue_job,  "cd :path; :environment_variable=:environment bundle exec script/enqueue :task :priority :output"


every 1.hour do
  rake 'openfoodnetwork:cache:check_products_integrity'
end

every 1.day, at: '12:05am' do
  run_file "lib/open_food_network/integrity_checker.rb"
end

# Checks whether there is a backup storage configured. Note the path this
# method refers to only exists in staging and production.
#
# @return [Boolean]
def backup_storage_setup?
  File.file?('../shared/config/db2fog.rb')
end

if backup_storage_setup?
  every 1.day, at: '2:45am' do
    rake 'db2fog:clean'
  end

  every 4.hours do
    rake 'db2fog:backup'
  end
end

every 5.minutes do
  enqueue_job 'HeartbeatJob', priority: 0
  enqueue_job 'SubscriptionPlacementJob', priority: 0
  enqueue_job 'SubscriptionConfirmJob', priority: 0
end

every 1.day, at: '1:00am' do
  rake 'openfoodnetwork:billing:update_account_invoices'
end

# On the 2nd of every month at 1:30am
every '30 1 2 * *' do
  rake 'openfoodnetwork:billing:finalize_account_invoices'
end
