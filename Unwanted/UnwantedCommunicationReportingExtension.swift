//
//  UnwantedCommunicationReportingExtension.swift
//  Unwanted
//
//  Created by Farzad Nazifi on 8/19/18.
//  Copyright © 2018 Farzad Nazifi. All rights reserved.
//

import UIKit
import IdentityLookup
import IdentityLookupUI
import PhoneNumberKit
import CoreTelephony
import CountryPicker

class UnwantedCommunicationReportingExtension: ILClassificationUIExtensionViewController, SelectiveViewDelegate, CountryPickerDelegate {
    
    var vc: NewRuleViewController!
    @IBOutlet var blockSwitch: UISwitch!
    @IBOutlet var junkView: SelectiveView!
    @IBOutlet var notJunkView: SelectiveView!
    @IBOutlet var autoBlockView: UIView!
    @IBOutlet weak var countryPicker: CountryPicker!
    var regionCode = ""
    var isCountryCodeNeed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gf = try! GetFilter(readOnly: false)
        notJunkView.delegate = self
        junkView.delegate = self
    }
    
    func selectiveDidTap(selective: SelectiveView) {
        if selective == junkView {
            junkView.isSelected = true
            notJunkView.isSelected = false
            autoBlockView.isHidden = false
            if isCountryCodeNeed{
                countryPicker.isHidden = false
            }else{
                countryPicker.isHidden = true
            }
        } else {
            junkView.isSelected = false
            notJunkView.isSelected = true
            autoBlockView.isHidden = true
            countryPicker.isHidden = true
        }
        
        self.extensionContext.isReadyForClassificationResponse = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Notify the system when you have completed gathering information
        // from the user and you are ready with a classification response
        self.extensionContext.isReadyForClassificationResponse = false
    }
    
    
    // Customize UI based on the classification request before the view is loaded
    override func prepare(for classificationRequest: ILClassificationRequest) {
        // Configure your views for the classification request
        if let calls = (classificationRequest as? ILCallClassificationRequest), let last = calls.callCommunications.last, let sender = last.sender {
            do {
                let phoneNumberKit = PhoneNumberKit()
                let phoneNumber = try phoneNumberKit.parse(sender)
                let number = phoneNumberKit.format(phoneNumber, toType: .e164)
                junkView.titleLabel?.text = phoneNumberKit.getRegionCode(of: phoneNumber)
            } catch let err {
                // Do not have a region code! Not A number error! Then raise country code selector!
                print(err)
                openCountryPicker()
            }
        }else if let messages = (classificationRequest as? ILMessageClassificationRequest), let last = messages.messageCommunications.last, let sender = last.sender {
            do {
                let phoneNumberKit = PhoneNumberKit()
                let phoneNumber = try phoneNumberKit.parse(sender)
                let number = phoneNumberKit.format(phoneNumber, toType: .e164)
                junkView.titleLabel?.text = phoneNumberKit.getRegionCode(of: phoneNumber)
            } catch let err{
                // Do not have a region code! Not A number error! Then raise country code selector!
                print(err)
                openCountryPicker()
            }
        }
    }
    
    // Provide a classification response for the classification request
    override func classificationResponse(for request:ILClassificationRequest) -> ILClassificationResponse {
        var response: ILClassificationResponse! = ILClassificationResponse(action: .none)
        var rule: UserRule!
        
        if let calls = (request as? ILCallClassificationRequest), let last = calls.callCommunications.last, let sender = last.sender {
            
            let phoneNumberKit = PhoneNumberKit()
            let phoneNumber = try! phoneNumberKit.parse(sender)
            let number = phoneNumberKit.format(phoneNumber, toType: .e164)
            
            junkView.titleLabel?.text = PhoneNumberKit.defaultRegionCode()
            
            if junkView.isSelected {
                rule = UserRule(m: nil, n: sender, r: UserRule.Rule.b, u: "anonymous", y: "a")
                if blockSwitch.isOn {
                    response = ILClassificationResponse(action: .reportJunkAndBlockSender)
                } else {
                    response = ILClassificationResponse(action: .reportJunk)
                }
            } else {
                response = ILClassificationResponse(action: .reportNotJunk)
                rule = UserRule(m: nil, n: sender, r: UserRule.Rule.a, u: "anonymous", y: "a")
            }
            
        } else if let messages = (request as? ILMessageClassificationRequest), let last = messages.messageCommunications.last, let sender = last.sender {
            
            if junkView.isSelected {
                rule = UserRule(m: nil, n: sender, r: UserRule.Rule.b, u: "anonymous", y: "a")
                if blockSwitch.isOn {
                    response = ILClassificationResponse(action: .reportJunkAndBlockSender)
                } else {
                    response = ILClassificationResponse(action: .reportJunk)
                }
            } else {
                response = ILClassificationResponse(action: .reportNotJunk)
                rule = UserRule(m: nil, n: sender, r: UserRule.Rule.a, u: "anonymous", y: "a")
            }
        } else {
            return ILClassificationResponse(action: .none)
        }
        return response
    }
    
    func countryPhoneCodePicker(_ picker: CountryPicker, didSelectCountryWithName name: String, countryCode: String, phoneCode: String, flag: UIImage) {
        regionCode = phoneCode
    }
    
    func openCountryPicker(){
//        countryPicker.isHidden = false
        isCountryCodeNeed = true
        //get corrent country
        let locale = Locale.current
        let code = (locale as NSLocale).object(forKey: NSLocale.Key.countryCode) as! String?
        //init Picker
        countryPicker.countryPickerDelegate = self
        countryPicker.showPhoneNumbers = true
        let theme = CountryViewTheme(countryCodeTextColor: .white, countryNameTextColor: .white, rowBackgroundColor: UIColor(displayP3Red: 17/255, green: 17/255, blue: 18/255, alpha: 1), showFlagsBorder: true) //optional
        countryPicker.theme = theme //optional
        countryPicker.setCountry(code!)
        
    }
}
