#
# Okapi: complete permission manager for Flutter.
# Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
# Use of this source code is governed by a BSD-style license (see LICENSE).
#
Pod::Spec.new do |s|
  s.name             = 'okapi'
  s.version          = '1.0.0'
  s.summary          = 'Okapi: complete permission manager for Flutter.'
  s.description      = <<-DESC
Check, request and guide users through every iOS permission with a
polished, customisable flow.
                       DESC
  s.homepage         = 'https://github.com/sanket-manohar/okapi'
  s.license          = { :type => 'BSD-3-Clause', :file => '../LICENSE' }
  s.author           = 'Sanket Santosh Vidya Manohar'
  s.source           = { :path => '.' }
  s.source_files     = 'okapi/Sources/okapi/**/*.swift'
  s.resource_bundles = { 'okapi_privacy' => ['okapi/Sources/okapi/Resources/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.9'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
