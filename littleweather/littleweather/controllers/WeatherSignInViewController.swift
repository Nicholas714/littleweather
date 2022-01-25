//
//  WeatherSignInViewController.swift
//  littleweather
//
//  Created by Nicholas Grana on 1/24/22.
//

import UIKit
import AuthenticationServices

protocol WeatherAuthenticationDelegate {
    func signIn(userID: String)
    func signOut()
}

@IBDesignable
class WeatherSignInButton: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        authButton = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .white)
    }
    
    var authButton: ASAuthorizationAppleIDButton!
    
    @IBInspectable var cornerRadius: CGFloat = 6.0
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        authButton = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .white)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        authButton.cornerRadius = cornerRadius
        addSubview(authButton)

        authButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            authButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            authButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            authButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            authButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
        ])
        
    }
    
}

class WeatherSignInViewController: UIViewController {
    
    @IBOutlet var signInButton: WeatherSignInButton!
    
    var signInDelegate: WeatherAuthenticationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.authButton.addTarget(self, action: #selector(handleSignInWithAppleClicked), for: .touchUpInside)
    }
    
    @objc func handleSignInWithAppleClicked() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = self
        authController.performRequests()
    }
    
}

extension WeatherSignInViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let cred = authorization.credential as? ASAuthorizationAppleIDCredential, let delegate = signInDelegate {
            delegate.signIn(userID: cred.user)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        NSLog("Error logging in \(error.localizedDescription)")
    }
    
}
