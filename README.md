# Zephyr SDK iOS

The Zephyr SDK is an easy-to-use toolkit that allows you to effortlessly integrate and utilize [Breeze 1 Click Checkout](https://breeze.in) & its services into your iOS app.

## iOS SDK Integration

Follow the below steps to integrate Zephyr SDK into your iOS application:

### Step 1: Installing the Zephyr SDK

1.1. Install the Zephyr SDK using Cocoapods by adding the following line to your Podfile:

```ruby
platform :ios, '12.0'
pod 'ZephyrSDK', '0.0.1'
```

Example:

```ruby
target 'your-app' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  platform :ios, '12.0'
  pod 'ZephyrSDK', '0.0.1'
end
```

1.2. Run `pod install` to install the Zephyr SDK.

### Step 2: Initialize the SDK

**2.1. Create an instance of the `Zephyr` class in your ViewController.**

```swift
// Import the Zephyr SDK
import ZephyrSDK

// Create an instance of the Zephyr class
let zephyr = Zephyr()
```

**2.2. Initiate the Zephyr instance. Preferably in the `viewDidLoad` method of your ViewController.**

In order to call initiate you need to perform the following steps:

#### 2.2.1: Construct the Initiate Payload

Create a NSDictionary with correct parameters to initiate the SDK. This is the data that will be used to initialize the SDK.

```swift
// Create a dictionary for the Initiate data
var initiatePayload: [String: Any] = [
    "merchantId": "<MERCHANT_ID>",
    "environment": "<ENVIRONMENT>",
    "shopUrl": "<SHOP_URL>"
]

// Place Initiate Payload into SDK Payload
var initSDKPayload: [String: Any] = [
    "requestId": "<UNIQUE_RANDOM_ID>",
    "service": "in.breeze.onecco",
    "payload": initiatePayload
]

```

Note: Obtain values for `merchantId`, `environment` and `shopUrl` from the Breeze team.

Refer to schemas for understanding what keys mean.

#### 2.2.2: Construct the Callback Method

During the user journey the SDK will call the callback method with the result of the SDK operation.
You need to implement this method in order to handle the result of the SDK operation.

```swift

func zephyrCallbackHandler(event: [String: Any]) {
    guard let eventName = event["eventName"] as? String,
          let eventData = event["eventData"] as? [String: Any] else {
        return
    }

    switch eventName {
    // Handle various events according to your desired logic
    default:
        break
    }
}

```

#### 2.2.3: Call the initiate method on Zephyr Instance

Finally, call the initiate method on the Zephyr instance with the payload and the callback method.
The first parameter is the context of the application.

```swift
zephyr.initiate(self, payload: initSDKPayload, callback: zephyrCallbackHandler)
```

### Step 3: Start processing your requests

Once the SDK is initiated, you can start processing your requests using the initialized instance of the SDK.
The SDK will call the callback method with the result of the SDK operation.

#### 3.1: Construct the Process Payload

Create a Json payload with the required parameters to process the request.
The process payload differs based on the request.
Refer to schemas sections to understand what kind of data is required for different requests

```swift

// 3.1 Create SDK Process Payload
// Create a dictionary for the Process data
var processPayload: [String: Any] = [
    "action": "<ACTION>"
    // and more parameters required as per the action
]

// Place Process Payload into SDK Payload
var processSDKPayload: [String: Any] = [
    "requestId": "<UNIQUE_RANDOM_ID>",
    "service": "in.breeze.onecco",
    "payload": processPayload
]

```

#### 3.2: Call the process method on Zephyr Instance

Call the process method on the Zephyr instance with the process payload to start the user journey or a headless flow.

```swift
zephyr.process(payload: processSDKPayload)
```
