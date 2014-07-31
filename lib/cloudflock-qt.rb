# Required to work around bug in Windows binary gem.
# Issue: https://github.com/ryanmelt/qtbindings/issues/69
require 'thread'
require 'Qt'
require 'cloudflock/app'
require 'cloudflock/task/server-profile'

# Public: Namespace for any application built around the CloudFlock API with a
# Qt interface.
module CloudFlockQt
  # Public: Version number of the current gem.
  VERSION = '0.7.2'
end
