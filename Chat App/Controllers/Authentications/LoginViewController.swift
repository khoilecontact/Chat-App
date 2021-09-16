//
//  LoginViewController.swift
//  Chat App
//
//  Created by KhoiLe on 30/08/2021.
//

import UIKit
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    var alertMessage = ""
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        // Continue to next field
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        
        field.backgroundColor = .secondarySystemBackground
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    private let FBloginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    
    private let googleSignInButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Login"
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        FBloginButton.delegate = self
        
        // Add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(FBloginButton)
        scrollView.addSubview(googleSignInButton)
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: size, y: 20, width: size, height: size)
        imageView.backgroundColor = .systemBackground
        
        emailField.frame = CGRect(x: 30, y: imageView.bottom + 40, width: scrollView.width - 60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 30 , width: scrollView.width - 60, height: 52)
        
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom + 30 , width: scrollView.width - 60, height: 52)
        
        FBloginButton.frame = CGRect(x: 30, y: loginButton.bottom + 30 , width: scrollView.width - 60, height: 52)
        
        googleSignInButton.frame = CGRect(x: 30, y: FBloginButton.bottom + 30 , width: scrollView.width - 60, height: 52)
    }
    
    @objc func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder() 
        
        let isValid = validate()
        
        if !isValid {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!, completion: { [weak self] authResult, error in
            
            DispatchQueue.main.async {
                self?.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Failed to login user with email: \(String(describing: self?.emailField.text!))")
                return
            }
            
            let user = result.user
            print("Logged in user: \(user)")
            
            guard let email = self?.emailField.text else { return }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Error in getting user's info: \(error)")
                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")
            
            self?.navigationController?.dismiss(animated: true, completion: nil)
        })
        
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Opps!", message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func googleSignInButtonTapped() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { user, error in
            guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                return
            }
            
            print("Did sign in with Google: \(String(describing: user))")
            
            guard let user = user else { return }
            
            guard let email = user.profile?.email, let firstName = user.profile?.givenName, let lastName = user.profile?.familyName else { return }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    // Insert user to DB
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            //upload image
                            if ((user.profile?.hasImage) != nil) {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    return
                                }
                                
                                URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                    let fileName = chatUser.profilePictureFileName
                                    
                                    guard let data = data else { return }
                                    
                                    storageManager.shared.uploadFrofilePicture(with: data, fileName: fileName, completion: { result in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.setValue(downloadUrl, forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage manager error: \(error)")
                                        }
                                    })
                                }).resume()
                            }
                            
                        }
                    })
                }
            })
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { authResult, error in
                guard authResult != nil, error == nil else {
                    print("Something is wrong when sign in Google")
                    return
                }
                
                print("Successfully log in with Google")
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            })
        }
    }
    
    
    
    func validate() -> Bool {
        guard let email = emailField.text, !email.isEmpty else {
            alertMessage = "Please enter an Email"
            return false
        }
        
        guard let password = passwordField.text, !password.isEmpty else {
            alertMessage = "Please enter a Password"
            return false
        }
        
        if !email.contains("@") {
            alertMessage = "Please input a valid email"
            return false
        }
        
        if password.count < 6 {
            alertMessage = "Password must contains at least 6 letters"
            return false
        }
        
        return true
    }
    
    
}


extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //nothing
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        // Unwraph token from Facebook
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with Facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start(completion: { connection, result, error in
            guard let result = result as? [String: Any ], error == nil else {
                print("Failed to make Facebook Graph request")
                return
            }
            
            //Debug
            //            print(result)
            //            return
            //
            guard let email = result["email"] as? String,
                  let firstName = result["first_name"] as? String, let lastName = result["last_name"] as? String, let picture = result["picture"] as? [String: Any], let data = picture["data"] as? [String: Any], let pictureUrl = data["url"] as? String
            else {
                print("Failed to get email and name from Facebook")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                if !exists {
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { [weak self] success in
                        if success {
                            //upload image
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                                
                                guard data != nil else { return }
                                guard error == nil else { return }
                                
                                guard let image = self?.imageView.image, let data = image.pngData() else {
                                    return
                                }
                                
                                let fileName = chatUser.profilePictureFileName
                                storageManager.shared.uploadFrofilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.setValue(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                                
                            }).resume()
                            
                        }
                    })
                }
            })
            
            //Create user in Firebase database - not in Authentication cuz it's already created in there
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            //Log in Firebase using Facebook
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard authResult != nil, error == nil else {
                    print("Facebook log in fail, MFA maybe needed")
                    return
                }
                
                print("Sucessfully log in")
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
        
    }
    
    
}

