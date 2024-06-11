import UIKit

@objc public protocol OTPFieldViewDelegate {
    func shouldBecomeFirstResponderForOTP(otpTextFieldIndex index: Int) -> Bool
    func enteredOTP(otp: String)
    func hasEnteredAllOTP(hasEnteredAll: Bool) -> Bool
}

@objc public enum DisplayType: Int {
    case circular
    case roundedCorner
    case square
    case diamond
    case underlinedBottom
}

@objc public enum KeyboardType: Int {
    case numeric
    case alphabet
    case alphaNumeric
}

@objc public class OTPFieldView: UIView {
    
    public var displayType: DisplayType = .roundedCorner
    public var otpInputType: KeyboardType = .numeric
    public var fieldFont: UIFont = UIFont.systemFont(ofSize: 25)
    public var secureEntry: Bool = false
    public var hideEnteredText: Bool = false
    public var requireCursor: Bool = true
    public var cursorColor: UIColor = UIColor.blue
    public var fieldSize: CGFloat = 50
    public var fieldBorderWidth: CGFloat = 2
    public var fieldBorderRadius: CGFloat = 10
    public var shouldAllowIntermediateEditing: Bool = true
    public var defaultBackgroundColor: UIColor = UIColor.clear
    public var filledBackgroundColor: UIColor = UIColor.clear
    public var defaultBorderColor: UIColor = UIColor.gray
    public var filledBorderColor: UIColor = UIColor.clear
    public var errorBorderColor: UIColor?
    
    public weak var delegate: OTPFieldViewDelegate?
    
    fileprivate var secureEntryData = [String]()
    
    public var fieldsCount: Int = 4 {
        didSet {
            initializeUI()
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        initializeUI()
    }
    
    public func initializeUI() {
        layer.masksToBounds = true
        layoutIfNeeded()
        
        initializeOTPFields()
        
        layoutIfNeeded()
        
        // Forcefully try to make first otp field as first responder
        (viewWithTag(1) as? OTPTextField)?.becomeFirstResponder()
    }
    
    fileprivate func initializeOTPFields() {
        secureEntryData.removeAll()
        
        for index in stride(from: 0, to: fieldsCount, by: 1) {
            let oldOtpField = viewWithTag(index + 1) as? OTPTextField
            oldOtpField?.removeFromSuperview()
            
            let otpField = getOTPField(forIndex: index)
            addSubview(otpField)
            
            secureEntryData.append("")
        }
    }
    
    fileprivate func getOTPField(forIndex index: Int) -> OTPTextField {
        let totalFieldWidth = fieldSize + 8
        let totalFieldsWidth = totalFieldWidth * CGFloat(fieldsCount)
        let remainingSpace = bounds.size.width - totalFieldsWidth
        let separatorSpace = remainingSpace / CGFloat(fieldsCount - 1)
        
        let fieldFrame = CGRect(
            x: CGFloat(index) * (totalFieldWidth + separatorSpace),
            y: (bounds.size.height - fieldSize) / 2,
            width: totalFieldWidth,
            height: fieldSize
        )
        
        let otpField = OTPTextField(frame: fieldFrame)
        otpField.delegate = self
        otpField.tag = index + 1
        otpField.font = fieldFont
        
        switch otpInputType {
        case .numeric:
            otpField.keyboardType = .numberPad
        case .alphabet:
            otpField.keyboardType = .alphabet
        case .alphaNumeric:
            otpField.keyboardType = .namePhonePad
        }
        
        otpField.otpBorderColor = defaultBorderColor
        otpField.otpBorderWidth = fieldBorderWidth
        
        otpField.tintColor = requireCursor ? cursorColor : UIColor.clear
        otpField.backgroundColor = defaultBackgroundColor
        otpField.initalizeUI(forFieldType: displayType, forFieldRadius: fieldBorderRadius)
        
        return otpField
    }
    
    fileprivate func isPreviousFieldsEntered(forTextField textField: UITextField) -> Bool {
        var isTextFilled = true
        var nextOTPField: UITextField?
        
        if !shouldAllowIntermediateEditing {
            for index in stride(from: 1, to: fieldsCount + 1, by: 1) {
                let tempNextOTPField = viewWithTag(index) as? UITextField
                
                if let tempNextOTPFieldText = tempNextOTPField?.text, tempNextOTPFieldText.isEmpty {
                    nextOTPField = tempNextOTPField
                    break
                }
            }
            
            if let nextOTPField = nextOTPField {
                isTextFilled = (nextOTPField == textField || (textField.tag) == (nextOTPField.tag - 1))
            }
        }
        
        return isTextFilled
    }
    
    fileprivate func calculateEnteredOTPString(isDeleted: Bool) {
        if isDeleted {
            _ = delegate?.hasEnteredAllOTP(hasEnteredAll: false)
            
            for index in stride(from: 0, to: fieldsCount, by: 1) {
                var otpField = viewWithTag(index + 1) as? OTPTextField
                
                if otpField == nil {
                    otpField = getOTPField(forIndex: index)
                }
                
                let fieldBackgroundColor = (otpField?.text ?? "").isEmpty ? defaultBackgroundColor : filledBackgroundColor
                let fieldBorderColor = (otpField?.text ?? "").isEmpty ? defaultBorderColor : filledBorderColor
                
                if displayType == .diamond || displayType == .underlinedBottom {
                    otpField?.shapeLayer.fillColor = fieldBackgroundColor.cgColor
                    otpField?.shapeLayer.strokeColor = fieldBorderColor.cgColor
                } else {
                    otpField?.backgroundColor = fieldBackgroundColor
                    otpField?.layer.borderColor = fieldBorderColor.cgColor
                }
            }
        } else {
            var enteredOTPString = ""
            
            for index in stride(from: 0, to: secureEntryData.count, by: 1) {
                if !secureEntryData[index].isEmpty {
                    enteredOTPString.append(secureEntryData[index])
                }
            }
            
            if enteredOTPString.count == fieldsCount {
                delegate?.enteredOTP(otp: enteredOTPString)
                
                let isValid = delegate?.hasEnteredAllOTP(hasEnteredAll: (enteredOTPString.count == fieldsCount)) ?? false
                
                for index in stride(from: 0, to: fieldsCount, by: 1) {
                    var otpField = viewWithTag(index + 1) as? OTPTextField
                    
                    if otpField == nil {
                        otpField = getOTPField(forIndex: index)
                    }
                    
                    if !isValid {
                        otpField?.layer.borderColor = (errorBorderColor ?? filledBorderColor).cgColor
                    } else {
                        otpField?.layer.borderColor = filledBorderColor.cgColor
                    }
                }
            }
        }
    }
}

extension OTPFieldView: UITextFieldDelegate {
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let shouldBeginEditing = delegate?.shouldBecomeFirstResponderForOTP(otpTextFieldIndex: (textField.tag - 1)) ?? true
        if shouldBeginEditing {
            return isPreviousFieldsEntered(forTextField: textField)
        }
        
        return shouldBeginEditing
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let replacedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
        
        if !replacedText.isEmpty && otpInputType == .alphabet && replacedText.rangeOfCharacter(from: .letters) == nil {
            return false
        }
        if !replacedText.isEmpty && otpInputType == .numeric && replacedText.rangeOfCharacter(from: .decimalDigits) == nil {
            return false
        }
        if !replacedText.isEmpty && otpInputType == .alphaNumeric && replacedText.rangeOfCharacter(from: .alphanumerics) == nil {
            return false
        }
        
        if (replacedText.count) >= 1 {
            if secureEntry {
                let index = (textField.tag - 1)
                if secureEntryData.count >= index {
                    secureEntryData[textField.tag - 1] = string
                } else {
                    secureEntryData.append(string)
                }
                
                textField.text = hideEnteredText ? "●" : string
            } else {
                textField.text = string
            }
            
            let nextOTPField = viewWithTag((textField.tag + 1)) as? UITextField
            
            if let nextOTPField = nextOTPField {
                nextOTPField.becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
            
            calculateEnteredOTPString(isDeleted: false)
            
            return false
        } else if (replacedText.count) == 0 {
            let previousOTPField = viewWithTag((textField.tag - 1)) as? UITextField
            textField.text = ""
            
            if secureEntry && (textField.tag - 1) < secureEntryData.count {
                secureEntryData[textField.tag - 1] = ""
            }
            
            if let previousOTPField = previousOTPField {
                previousOTPField.becomeFirstResponder()
            }
            
            calculateEnteredOTPString(isDeleted: true)
            
            return false
        }
        
        return true
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        let textFieldTag = textField.tag
        
        if displayType == .diamond || displayType == .underlinedBottom {
            let fieldBackgroundColor = (textField.text ?? "").isEmpty ? defaultBackgroundColor : filledBackgroundColor
            let fieldBorderColor = (textField.text ?? "").isEmpty ? defaultBorderColor : filledBorderColor
            
            let otpField = textField as? OTPTextField
            otpField?.shapeLayer.fillColor = fieldBackgroundColor.cgColor
            otpField?.shapeLayer.strokeColor = fieldBorderColor.cgColor
        }
    }
}
