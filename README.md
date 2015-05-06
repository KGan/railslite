#  Rails Lite

A project in understanding the rails framework, REST request lifecycle, MVC abstractions (ORM models, Controllers, View templating) and metaprogramming (route generations).
Also includes associations and validations for the models similar to ActiveRecord, generating the necessary SQL query and mapping the response to the correct ruby class models 

## Usage...if you insist
Clone the repo and run `ruby  bin/bonus_server.rb`.
Your routes are defined in `lib/finalized/routes.rb`.
There is no separate folder for loading controller or model class files into yet, you'll have to smash them into the bonus server like the examples.
Views are in `views` and you have access to the cookie through session (persisted) and flash (both flash and flash.now work).

