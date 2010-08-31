# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_charts_session',
  :secret      => '3b82873ccf962278f5ebd6043878a9adff0a08580dbde054cd5f28379712e637dbc4473f49f8380e6f2c163fc82b5a422b154049ec585eb110a0dce8254d5132'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
