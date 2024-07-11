
Pod::Spec.new do |spec|
  spec.name         = "ZephyrSDK"
  spec.version      = "0.0.1"
  spec.summary      = "Integrate Breeze 1 Click Checkout to your app."
  spec.description  = <<-DESC
                      Zephyr SDK library which enables you to seamlessly integrate and use Breeze 1 Click Checkout in your iOS app.
                      DESC
  spec.homepage     = "https://breeze.in/"
  spec.license      = "MIT"
  spec.author       = { "Sahil Sinha" => "sahilsinha.dar@gmail.com" }
  spec.platform     = :ios, "12.0"
  spec.source       = { :git => "https://github.com/juspay/zephyr-sdk-ios.git", :tag => "#{spec.version}" }
  spec.source_files  = "zephyr/**/*.{h,m,swift}"
end
