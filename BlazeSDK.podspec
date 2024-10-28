Pod::Spec.new do |spec|
  spec.name                   = 'BlazeSDK'
  spec.version                = "0.1.0"
  spec.summary                = "Integrate Breeze 1 Click Checkout to your app."
  spec.description            = <<-DESC
                                  BlazeSDK is library which enables you to seamlessly integrate and use Breeze 1 Click Checkout in your iOS app.
                                  DESC
  spec.homepage               = "https://breeze.in/"
  spec.license                = "MIT"
  spec.author                 = { "Sahil Sinha" => "sahilsinha.dar@gmail.com" }
  spec.source                 = { :git => 'https://github.com/juspay/blaze-sdk-ios.git', :tag => spec.version.to_s }
  spec.ios.deployment_target  = '12.0'
  spec.source_files            = 'BlazeSDK/Classes/**/*'
  spec.swift_version          = '5.0'
  spec.swift_versions         = ['5.0']
end
