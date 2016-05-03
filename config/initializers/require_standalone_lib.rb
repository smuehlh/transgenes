# cannot autoload, since some files are monkeypatches of existing classes.
Dir[Rails.root + 'lib/standalone/lib/**/*.rb'].each do |file|
    require file
end
ErrorHandling.is_commandline_tool = false
