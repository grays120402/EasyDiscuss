# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'EasyDiscuss' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for EasyDiscuss

post_install do |installer|
 installer.pods_project.build_configurations.each do |config|
 config.build_settings.delete(‘CODE_SIGNING_ALLOWED’)
 config.build_settings.delete(‘CODE_SIGNING_REQUIRED’)
 end
end
pod 'ZHDropDownMenu'
pod 'Firebase/Crashlytics'
pod 'Firebase/Firestore'
pod 'Firebase/Storage'
pod 'FirebaseFirestoreSwift'
pod 'IQKeyboardManagerSwift'
pod 'Firebase/Auth'
pod 'SDWebImage'
pod "KRProgressHUD"
pod "GoogleSignIn"
 pod "GoogleAPIClientForREST/Drive"
end
