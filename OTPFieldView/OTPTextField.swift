class OTPTextField: UITextField {
    
    var otpBorderColor: UIColor = UIColor.black {
        didSet {
            initalizeUI(forFieldType: .roundedCorner, forFieldRadius: 10)
        }
    }
    
    var otpBorderWidth: CGFloat = 2 {
        didSet {
            initalizeUI(forFieldType: .roundedCorner, forFieldRadius: 10)
        }
    }
    
    let shapeLayer = CAShapeLayer()
    
    override public var text: String? {
        didSet {
            let filledColor = (text ?? "").isEmpty ? UIColor.clear.cgColor : UIColor.black.cgColor
            layer.backgroundColor = filledColor
        }
    }
    
    func initalizeUI(forFieldType type: DisplayType, forFieldRadius cornerRadius: CGFloat = 10) {
        layer.masksToBounds = true
        
        switch type {
        case .circular:
            layer.cornerRadius = self.bounds.size.height / 2
        case .square:
            layer.cornerRadius = 0
        case .diamond:
            addDiamondMaskLayer()
        case .underlinedBottom:
            addBottomLineLayer()
        default:
            layer.cornerRadius = cornerRadius
        }
        
        layer.borderColor = otpBorderColor.cgColor
        layer.borderWidth = otpBorderWidth
    }
    
    fileprivate func addDiamondMaskLayer() {
        let path = UIBezierPath()
        let size = self.bounds.size
        path.move(to: CGPoint(x: 0, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width / 2, y: 0))
        path.addLine(to: CGPoint(x: size.width, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width / 2, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height / 2))
        
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.lineWidth = otpBorderWidth
        shape.strokeColor = otpBorderColor.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shapeLayer.removeFromSuperlayer()
        shapeLayer.frame = bounds
        layer.insertSublayer(shape, at: 0)
        shapeLayer.mask = shape
    }
    
    fileprivate func addBottomLineLayer() {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: self.frame.height - otpBorderWidth, width: self.frame.width, height: otpBorderWidth)
        bottomLine.backgroundColor = otpBorderColor.cgColor
        layer.addSublayer(bottomLine)
    }
}
