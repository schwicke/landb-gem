require 'rake'

Gem::Specification.new do |s|
  s.name        = 'landb'
  s.version     = '0.0.1'
  s.date        = '2012-08-17'
  s.summary     = "This is a WSDL dynamic wrapper for lanDB to puppet use."
  s.description = "This is a WSDL dynamic wrapper for lanDB to puppet use. It's writen from Anastasis Andronidis as an OpenLab Summer Student project"
  s.authors     = ["Anastasios Andronidis"]
  s.email       = 'anastasis90@yahoo.gr'
  s.files       = FileList['lib/**/*.rb'].to_a
	s.homepage    = 'https://gitgw.cern.ch/gitweb/?p=gem-landb.git;a=summary;js=1'
end
