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
        initiatePayload["merchantId"] = "d2cstore"
        initiatePayload["environment"] = "release"
        initiatePayload["shopUrl"] = "https://breeze-it-store.myshopify.com"
        return initiatePayload
    }

    func createStartCheckoutPayload() -> [String: Any] {
        let cartString = """
            {
            "token":
                "hWN398h1MYYGTJK83e2rDznA?key=29cbc71d22b49a79cb8e25229de5813d",
            "note": "",
            "attributes": {},
            "original_total_price": 1400,
            "total_price": 1400,
            "total_discount": 0,
            "total_weight": 0.0,
            "item_count": 2,
            "items": [
              {
                "id": 44182614474984,
                "properties": {},
                "quantity": 2,
                "variant_id": 44182614474984,
                "key": "44182614474984:14a856f03fde63adbb7df3da56d64b10",
                "title": "Blackout Shirt - black",
                "price": 700,
                "original_price": 700,
                "presentment_price": 7.0,
                "discounted_price": 700,
                "line_price": 1400,
                "original_line_price": 1400,
                "total_discount": 0,
                "discounts": [],
                "sku": "1233",
                "grams": 0,
                "vendor": "Bombay Shirt Company",
                "taxable": true,
                "product_id": 8070198591720,
                "product_has_only_default_variant": false,
                "gift_card": false,
                "final_price": 700,
                "final_line_price": 1400,
                "url": "/products/blackout-shirt?variant=44182614474984",
                "featured_image": {
                  "aspect_ratio": 1.0,
                  "alt": "Blackout Shirt",
                  "height": 1200,
                  "url":
                      "https://cdn.shopify.com/s/files/1/0647/6526/4104/products/bmb1.webp?v=1670259737",
                  "width": 1200
                },
                "image":
                    "https://cdn.shopify.com/s/files/1/0647/6526/4104/products/bmb1.webp?v=1670259737",
                "handle": "blackout-shirt",
                "requires_shipping": true,
                "product_type": "",
                "product_title": "Blackout Shirt",
                "product_description": "Built for your adventures after dark.",
                "variant_title": "black",
                "variant_options": ["black"],
                "options_with_values": [
                  {"name": "Color", "value": "black"}
                ],
                "line_level_discount_allocations": [],
                "line_level_total_discount": 0,
                "has_components": false
              }
            ],
            "requires_shipping": true,
            "currency": "INR",
            "items_subtotal_price": 1400,
            "cart_level_discount_applications": [],
            "discount_codes": []
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
        processPayload["signature"] =
            "T4BRKwHKWfkWRLgF5ecss2+2tyID4zKVUqkfEgdFS73lyAokBq92VJRz4g+xzCcUE84ZNl7oQ9t26i8zGQLgh/B/6vNliM9u7VMX0soYDC9pEWd4TsWeetlYMzl/UIzitYan5q9aQ2UfS7HENHQGvGfOjsa75gP3SVwpufK8Sb1VFRFsnJKsXzgWq+y9iWLieJe596poEzUP2Wkt17mSGwH9rWukTy5S1ddZoZXUxDQiMtfXFj9NOnPDUA8psmERifivaD8IvhMEYwlEk+u6MrxF7IhasBs8dYGEZW+YDeaRz6mzK37sarYWgCUJgEYTJ97rmcRedgvnj+28YES/pw=="
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
        blaze.initiate(
            context: self, initiatePayload: createSDKPayload(payload: createInitiatePayload()),
            callbackFn: { (response) in
                print("response: \(response)")
            })
    }

    @IBAction func onProcessClick(_ sender: Any) {
        blaze.process(payload: createSDKPayload(payload: createStartCheckoutPayload()))
    }

}
