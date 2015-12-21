#!/usr/bin/env ruby

commands = [
  'bundle exec sidekiq -c 2 -r ./spec/integration/support/config.rb',
  'bundle exec ruby spec/integration/support/sinatra.rb'
]

pids = commands.map { |c| Process.spawn c }

shutdown = proc { Process.kill 'TERM', *pids }

Signal.trap 'INT',  &shutdown
Signal.trap 'TERM', &shutdown

Process.waitall
