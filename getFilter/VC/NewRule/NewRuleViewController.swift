//
//  NewRuleViewController.swift
//  getFilter
//
//  Created by Farzad Nazifi on 7/8/18.
//  Copyright © 2018 Farzad Nazifi. All rights reserved.
//

import UIKit
import PhoneNumberKit
import CoreTelephony
import CloudKit
import KeyboardWrapper

class NewRuleViewController: UIViewController, SelectiveViewDelegate, UITextFieldDelegate {
    
    required init?(coder aDecoder: NSCoder) { fatalError("...") }
    
    @IBOutlet var phoneView: SelectiveView!
    @IBOutlet var textView: SelectiveView!
    @IBOutlet var allowView: SelectiveView!
    @IBOutlet var blockView: SelectiveView!
    
    @IBOutlet var numberField: PhoneNumberTextField!
    @IBOutlet var textField: UITextField!
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var saveButton: UIButton!
    
    @IBOutlet var phoneTopConstraint: NSLayoutConstraint!
    @IBOutlet var textTopConstraint: NSLayoutConstraint!

    let gf: GetFilter
    var keyboardWrapper: KeyboardWrapper!
    var tempRule: UserRule?
    var currentUser: String!
    
    init(gf: GetFilter) {
        self.gf = gf
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.4)])
        numberField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.4)])

        keyboardWrapper = KeyboardWrapper(delegate: self)
        
        phoneView.delegate = self
        textView.delegate = self
        allowView.delegate = self
        blockView.delegate = self
        
        _ = gf.getUser().done { (user) in
            self.currentUser = user
            }.catch { (err) in
                self.dismiss(animated: true, completion: nil)
        }
        
        guard let tempRule = tempRule else {
            deleteButton.isHidden = true
            return
        }
        
        saveButton.isEnabled = true
        
        if let _ = tempRule.n {
            selectiveDidTap(selective: phoneView)
        }else {
            selectiveDidTap(selective: textView)
        }
        
        if tempRule.r == .a {
            selectiveDidTap(selective: allowView)
        }else {
            selectiveDidTap(selective: blockView)
        }
        
        titleLabel.text = "Update Rule"
        textField.text = tempRule.m
        numberField.text = tempRule.n
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func cancelTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteTapped(_ sender: UIButton) {
        gf.storage.deleteRule(id: tempRule!.id).done { () in
            self.dismiss(animated: true, completion: nil)
            }.catch { (err) in
                print(err)
        }
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        var number: String? = nil
        if phoneView.isSelected {
            let phoneNumberKit = PhoneNumberKit()
            let phoneNumber = try! phoneNumberKit.parse(numberField.text!)
            number = phoneNumberKit.format(phoneNumber, toType: .e164)
        }
        
        var text: String? = nil
        if textView.isSelected && textField.text!.count > 2 {
            text = textField.text
        }
        
        tempRule?.n = number
        tempRule?.m = text
        tempRule?.synced = false
        
        let rule = (tempRule != nil) ? tempRule! : UserRule(m: text, n: number, r: (allowView.isSelected ? .a : .b), u: "_98b0f26c3ed9541cde96b0a325c85ba1", y: numberField.defaultRegion)
        gf.storage.newUpdateRule(rule: rule).done { () in
            self.dismiss(animated: true, completion: nil)
            }.catch { (err) in
                print(err.localizedDescription)
                UIAlertController.error(error: err, source: self)
        }
    }
    
    func selectiveDidTap(selective: SelectiveView) {
        selective.isSelected = true
        switch selective {
        case phoneView:
            textField.isHidden = true
            numberField.isHidden = false
            textView.isSelected = false
        case textView:
            textField.isHidden = false
            numberField.isHidden = true
            phoneView.isSelected = false
        case blockView:
            allowView.isSelected = false
        case allowView:
            blockView.isSelected = false
        default: break
        }
        
        numberField.attributedPlaceholder = NSAttributedString(string: "Enter " + (phoneView.isSelected ? "phone number " : "text ") + "to " + (allowView.isSelected ? "allow" : "block"), attributes: [NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.4)])
        textField.attributedPlaceholder = NSAttributedString(string: "Enter " + (phoneView.isSelected ? "phone number " : "text ") + "to " + (allowView.isSelected ? "allow" : "block"), attributes: [NSAttributedString.Key.foregroundColor : UIColor.white.withAlphaComponent(0.4)])
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.textField {
            if textField.text!.count > 2 {
                saveButton.isEnabled = true
            }else {
                saveButton.isEnabled = false
            }
        }else {
            if numberField.isValidNumber {
                saveButton.isEnabled = true
            }else {
                saveButton.isEnabled = false
            }
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

protocol SelectiveViewDelegate {
    func selectiveDidTap(selective: SelectiveView)
}

class SelectiveView: UIView {
    var delegate: SelectiveViewDelegate?

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel?
    @IBOutlet var detailLabel: UILabel?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }
    
    @IBInspectable public var isSelected: Bool = false {
        didSet {
            update()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        update()
    }
    
    @objc func didTap() {
        delegate?.selectiveDidTap(selective: self)
    }

    func update() {
        if !isSelected {
            let disabledColor = #colorLiteral(red: 0.2705882353, green: 0.2705882353, blue: 0.2901960784, alpha: 1)
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
            imageView?.tintColor = disabledColor
            titleLabel?.textColor = disabledColor
            detailLabel?.textColor = disabledColor
        }else{
            titleLabel?.textColor = .white
            detailLabel?.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4)
            layer.borderWidth = 1
            switch titleLabel?.text! {
            case "Phone", "Text":
                layer.borderColor = #colorLiteral(red: 0.09019607843, green: 0.4745098039, blue: 0.9176470588, alpha: 1).cgColor
                imageView.tintColor = #colorLiteral(red: 0.09019607843, green: 0.4745098039, blue: 0.9176470588, alpha: 1)
            case "Allow":
                layer.borderColor = #colorLiteral(red: 0, green: 0.8157687783, blue: 0.1033710912, alpha: 1).cgColor
                imageView.tintColor = #colorLiteral(red: 0, green: 0.8157687783, blue: 0.1033710912, alpha: 1)
            case "Block":
                layer.borderColor = #colorLiteral(red: 0.9146965146, green: 0.3095251918, blue: 0.2168177068, alpha: 1).cgColor
                imageView.tintColor = #colorLiteral(red: 0.9146965146, green: 0.3095251918, blue: 0.2168177068, alpha: 1)
            case "Junk":
                layer.borderColor = #colorLiteral(red: 0.9146965146, green: 0.3095251918, blue: 0.2168177068, alpha: 1).cgColor
            case "Not Junk":
                layer.borderColor = #colorLiteral(red: 0, green: 0.8157687783, blue: 0.1033710912, alpha: 1).cgColor
            default: break;
            }
        }
    }
}

extension NewRuleViewController: KeyboardWrapperDelegate {
    func keyboardWrapper(_ wrapper: KeyboardWrapper, didChangeKeyboardInfo info: KeyboardInfo) {
        if info.state == .willShow || info.state == .visible {
            let pad = view.frame.height - 500 - info.endFrame.size.height
            if pad < 0 {
                phoneTopConstraint.constant = pad
                textTopConstraint.constant = pad
            }else {
                phoneTopConstraint.constant = 4
                textTopConstraint.constant = 4
            }
        } else {
            phoneTopConstraint.constant = 4
            textTopConstraint.constant = 4
        }
        
        view.layoutIfNeeded()
    }
}

extension UIAlertController {
    static func error(error: Error, source: UIViewController) {
        let vc = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
        vc.addAction(ok)
        source.present(vc, animated: true, completion: nil)
    }
}
