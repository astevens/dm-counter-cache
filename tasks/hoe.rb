Hoe.plugin :gemspec
hoe = Hoe.spec GEM_NAME do |p|
  p.version = GEM_VERSION
  p.author = AUTHOR
  p.email  = EMAIL

  p.description = PROJECT_DESCRIPTION
  p.summary = PROJECT_SUMMARY
  p.url = PROJECT_URL

  p.rubyforge_name = PROJECT_NAME if PROJECT_NAME

  p.clean_globs |= GEM_CLEAN
  p.spec_extras = GEM_EXTRAS if GEM_EXTRAS

  GEM_DEPENDENCIES.each do |dep|
    p.extra_deps << dep
  end

end