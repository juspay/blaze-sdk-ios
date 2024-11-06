//
//  ViewController.swift
//  BlazeSDK
//
//  Created by Sahil Sinha on 10/20/2024.
//  Copyright (c) 2024 Sahil Sinha. All rights reserved.
//

import BlazeSDK
import UIKit

class ViewController: UIViewController {

    let blaze = Blaze()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func createSDKPayload(payload: [String: Any]) -> [String: Any] {
        var sdkPayload = [String: Any]()
        sdkPayload["requestId"] = UUID().uuidString
        sdkPayload["service"] = "in.breeze.onecco"
        sdkPayload["payload"] = payload
        return sdkPayload
    }

    func createInitiatePayload() -> [String: Any] {
        var initiatePayload = [String: Any]()
        initiatePayload["merchantId"] = "d2cstorebeta"
        initiatePayload["environment"] = "beta"
        initiatePayload["shopUrl"] = "https://d2c-store-beta.myshopify.com"
        return initiatePayload
    }

    func createStartCheckoutPayload() -> [String: Any] {
        let cartString = """
        {
            "token": "c1-473243a885065ad7c911dc334255d73e",
            "note": "",
            "attributes": {
                "bundleData": "-",
                "discountName": "-",
                "variant_ids": "-",
                "target_variant_ids": "-",
                "discount": "-"
            },
            "original_total_price": 100,
            "total_price": 100,
            "total_discount": 0,
            "total_weight": 0.0,
            "item_count": 1,
            "items": [
                {
                    "id": 45938457084219,
                    "properties": {},
                    "quantity": 1,
                    "variant_id": 45938457084219,
                    "key": "45938457084219:7df34184-c212-44dc-8d8e-8954b890646d",
                    "title": "Sony PS5 Digital Standalone",
                    "price": 100,
                    "original_price": 100,
                    "discounted_price": 100,
                    "line_price": 100,
                    "original_line_price": 100,
                    "total_discount": 0,
                    "discounts": [],
                    "sku": "",
                    "grams": 0,
                    "vendor": "Sony",
                    "taxable": true,
                    "product_id": 8561540628795,
                    "product_has_only_default_variant": true,
                    "gift_card": false,
                    "final_price": 100,
                    "final_line_price": 100,
                    "url": "/products/sony-ps5-digital-standalone?variant=45938457084219",
                    "featured_image": {
                        "aspect_ratio": 1.0,
                        "alt": "Sony PS5 Digital Standalone",
                        "height": 679,
                        "url": "https://cdn.shopify.com/s/files/1/0684/1624/1979/files/51wPWj--fAL._SX679.jpg?v=1690641107",
                        "width": 679
                    },
                    "image": "https://cdn.shopify.com/s/files/1/0684/1624/1979/files/51wPWj--fAL._SX679.jpg?v=1690641107",
                    "handle": "sony-ps5-digital-standalone",
                    "requires_shipping": true,
                    "product_type": "",
                    "product_title": "Sony PS5 Digital Standalone",
                    "product_description": "Maximize your play sessions with near instant load times for installed PS5 games. The custom integration of the PS5 console's systems lets creators pull data from the SSD so quickly that they can design games in ways never before possible. Immerse yourself in worlds with a new level of realism as rays of light are individually simulated, creating true-to-life shadows and reflections in supported PS5 games. Play your favorite PS5 games on your stunning 4K TV. Enjoy smooth and fluid high frame rate gameplay at up to 120fps for compatible games, with support for 120Hz output on 4K displays. With an HDR TV, supported PS5 games display an unbelievably vibrant and lifelike range of colors. PS5 consoles support 8K Output, so you can play games on your 4320p resolution display. Immerse yourself in soundscapes where it feels as if the sound comes from every direction. Through your headphones or TV speakers your surroundings truly come alive with Tempest 3D AudioTech in supported games. Experience haptic feedback via the DualSense wireless controller in select PS5 titles and feel the effects and impact of your in-game actions through dynamic sensory feedback. Get to grips with immersive adaptive triggers, featuring dynamic resistance levels which simulate the physical impact of in-game activities in select PS5 games.",
                    "variant_title": null,
                    "variant_options": ["Default Title"],
                    "options_with_values": [{"name": "Title", "value": "Default Title"}],
                    "line_level_discount_allocations": [],
                    "line_level_total_discount": 0,
                    "has_components": false
                }
            ],
            "requires_shipping": true,
            "currency": "INR",
            "items_subtotal_price": 100,
            "cart_level_discount_applications": []
        }
        """

        var processPayload = [String: Any]()
        processPayload["cart"] = convertToDictionary(text: cartString)
        processPayload["action"] = "startCheckout"
        return processPayload
    }
    
    @IBAction func onProcessV2(_ sender: Any) {
        blaze.process(payload: createSDKPayload(payload: createCustomStartCheckoutPayload()))

    }
    
    
    func createCustomStartCheckoutPayload() -> [String: Any] {
        let cartString = """
        {
            "id": "7feaa429-308d-49b7-8461-46bfa4b37ff7",
            "items": [
                {
                    "id": "3aecf419-6823-4581-a093-0c90c5b5e1fc",
                    "title": "Apple iPhone 7 Plus",
                    "variantTitle": "256 GB / GOLD",
                    "image": "https://dfelk5npz6ka0.cloudfront.net/products/40767940985052.jpg",
                    "quantity": 1,
                    "initialPrice": 100,
                    "finalPrice": 100,
                    "discount": 0
                }
            ],
            "initialPrice": 100,
            "totalPrice": 100,
            "totalDiscount": 0,
            "itemCount": 1,
            "currency": "INR"
        }
        """
        
        var processPayload = [String: Any]()
        processPayload["action"] = "startCheckout"
        processPayload["cart"] = convertToDictionary(text: cartString)
        processPayload["signature"] = "T4BRKwHKWfkWRLgF5ecss2+2tyID4zKVUqkfEgdFS73lyAokBq92VJRz4g+xzCcUE84ZNl7oQ9t26i8zGQLgh/B/6vNliM9u7VMX0soYDC9pEWd4TsWeetlYMzl/UIzitYan5q9aQ2UfS7HENHQGvGfOjsa75gP3SVwpufK8Sb1VFRFsnJKsXzgWq+y9iWLieJe596poEzUP2Wkt17mSGwH9rWukTy5S1ddZoZXUxDQiMtfXFj9NOnPDUA8psmERifivaD8IvhMEYwlEk+u6MrxF7IhasBs8dYGEZW+YDeaRz6mzK37sarYWgCUJgEYTJ97rmcRedgvnj+28YES/pw=="
        processPayload["keyId"] = "90701"
        return processPayload
    }

    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }


    @IBAction func onInitiateClick(_ sender: Any) {
        blaze.initiate(context: self, initiatePayload: createSDKPayload(payload: createInitiatePayload()), callbackFn: { (response) in
            print("response: \(response)")
        })
    }


    @IBAction func onProcessClick(_ sender: Any) {
        blaze.process(payload: createSDKPayload(payload: createStartCheckoutPayload()))
    }

}

