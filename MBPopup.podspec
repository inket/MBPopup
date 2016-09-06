#
# Be sure to run `pod lib lint MBPopup.podspec` to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "MBPopup"
  s.version          = "0.1.0"
  s.summary          = "macOS status bar popups done right."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don"t worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
The summary is enough. I thought that was the case, but `pod lib lint` told me that it's not.
So here I am, just padding text because I can't think of anything to say.
                       DESC

  s.homepage         = "https://github.com/inket"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Mahdi Bchetnia" => "mahdi@outlook.com" }
  s.source           = { :git => "https://github.com/inket/MBPopup.git", :tag => s.version.to_s }
  s.social_media_url = "https://twitter.com/inket"

  s.platform = :osx, "10.10"

  s.source_files = "MBPopup/**/*"
  s.public_header_files = "MBPopup/**/*.h"
end
