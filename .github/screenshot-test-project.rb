require 'xcodeproj'
project = Xcodeproj::Project.open('PanelReader.xcodeproj')
app = project.targets.find { |t| t.name == 'PanelReader' }
test = project.new_target(:ui_test_bundle, 'ScreenshotsUITests', :ios, '17.0')
test.add_dependency(app)
reference = project.main_group.new_file('.github/CaptureTests.swift')
test.source_build_phase.add_file_reference(reference)
test.build_configurations.each do |config|
  config.build_settings.merge!({
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.yeetozer.comicport.screenshots',
    'GENERATE_INFOPLIST_FILE' => 'YES',
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '2',
    'TEST_TARGET_NAME' => 'PanelReader',
    'CODE_SIGNING_ALLOWED' => 'NO'
  })
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(test)
scheme.save_as(project.path, 'Screenshots')
