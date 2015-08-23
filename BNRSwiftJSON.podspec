Pod::Spec.new do |s|

  s.name         = "BNRSwiftJSON"
  s.version      = "1.0.0"
  s.summary      = "A JSON parsing library written in Swift"

  s.description  = <<-DESC
                   BNR Swift JSON
                   -
                   BNRSwiftJSON is a reusable framework for parsing JSON in Swift. 
                   Its primary goal is faciliate the safe parsing of JSON, while also preserving the ease of use presented by parsing JSON in Objective-C.
                   DESC

  s.homepage     = "https://github.com/bignerdranch/bnr-swift-json"

  s.license      = { :type => "MIT", :file => "LISCENSE" }

  s.authors    = {"Matt Mathias" => "mattm@bignerdranch.com", "John Gallagher" => "jgallagher@bignerdranch.com", "Zach Waldowski" => "zachary@bignerdranch.com"}

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"

  s.source = {:git => "https://github.com/bignerdranch/bnr-swift-json.git", :tag => "1.0.0"}
  s.source_files  = "BNRSwiftJSON/BNRSwiftJSON/*.swift"
  s.public_header_files = "BNRSwiftJSON/BNRSwiftJSON/BNRSwiftJSON.h"

  s.dependency 'Result'

end
