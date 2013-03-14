#!/bin/bash -xe
export DISPLAY=:99
export GOVUK_APP_DOMAIN=test.gov.uk
export GOVUK_ASSET_ROOT=http://static.test.gov.uk
export TEST_ENV_NUMBER=1
env

# Generate directories for upload tests
mkdir -p ./incoming-uploads
mkdir -p ./clean-uploads
mkdir -p ./attachment-cache

time bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment

RAILS_ENV=test time bundle exec rake db:reset db:schema:load --trace
RAILS_ENV=production SKIP_OBSERVERS_FOR_ASSET_TASKS=true time bundle exec rake assets:clean --trace
RAILS_ENV=test CUCUMBER_FORMAT=progress time bundle exec rake ci:setup:minitest default test:cleanup --trace
RAILS_ENV=production SKIP_OBSERVERS_FOR_ASSET_TASKS=true time bundle exec rake assets:precompile --trace

EXIT_STATUS=$?
echo "EXIT STATUS: $EXIT_STATUS"
exit $EXIT_STATUS