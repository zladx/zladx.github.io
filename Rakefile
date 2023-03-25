require 'i18n'
require 'readline'
require 'socket'

I18n.available_locales = [:en, :fr]

# Helpers
# =======

# Execute a system command, but raise an exception in case of error.
def system!(*args)
  result = system(*args)
  if result.nil?
    raise StandardError, "Command execution failed (#{$?})"
  elsif result == false
    raise StandardError, "Command returned a non-zero exit code (#{$?})"
  end
end

# Retry a block during some time if the given exception is thrown.
def retriable(exceptions:, timeout:)
  return_value = false
  start = Time.now
  begin
    yield
  rescue *exceptions => e
    if (Time.now - start < timeout) then retry else raise StandardError.new("Timeout") end
  end
end

# Tasks
# =====

desc "Run the website locally"
task :run do
  port = 4000

  # Wait for the local server to be ready, then open the default web browser
  pid = Process.fork do
    retriable(exceptions: [Errno::ECONNREFUSED, Errno::ETIMEDOUT], timeout: 10) do
      Socket.tcp("127.0.0.1", port, connect_timeout: 1) {}
    end
    puts "Rake: localhost:#{port} is reachable. Opening the default web browser…"
    system!("open http://localhost:#{port}/")
  end
  Process.detach(pid)

  system!("bundle exec jekyll serve")
end

desc "Create a new empty post"
task :new do
  title = Readline.readline("Title: ", false)
  raise "Title must be provided" if title == ""

  slug = ""
  suggested_slug = I18n.transliterate(title).downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  answer = Readline.readline("Slug [#{suggested_slug}]: ", false)
  if answer != ""
    slug = answer
  else
    slug = suggested_slug
  end

  date = Time.now.strftime('%Y-%m-%d')
  date_and_time = Time.now.strftime('%Y-%m-%d %H:%M')
  post_file = "_posts/#{date}-#{slug}.md"

  File.open(post_file, 'a+') do |f|
    f.write <<-FILE.gsub(/^\s*/, '')
      ---
      layout: post
      title: "#{title}"
      date: #{date_and_time}
      ---
    FILE
  end

  editor = ENV['BLOG_EDITOR'] || ENV['EDITOR']
  if editor
    system!("#{editor} #{post_file}")
  end
end

desc "Generate the static blog files"
task :build do
  system!('bundle exec jekyll build -d public')
end

desc "Commit the changes (if any)"
task :commit do
  has_changes = system('test -n "`git status --porcelain`"')
  if has_changes
    system!('git add -A && git commit')
  end
end

desc "Push sources to Github (commiting the changes before if any)"
task :push => [:commit] do
  system!('git push')
end

desc "Build, commit and push the site"
task :publish => [:build, :push]  do
end

