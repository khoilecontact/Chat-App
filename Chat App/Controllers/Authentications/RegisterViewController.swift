//
//  RegisterViewController.swift
//  Chat App
//
//  Created by KhoiLe on 30/08/2021.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController, UINavigationControllerDelegate {
    var showingAlert = false
    var alertMessage = ""
    
    private let spinner = JGProgressHUD(style: .dark)
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    let imageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    let emailField: UITextField = {
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
    
    let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password... (>= 6 letters)"
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        
        return field
    }()
    
    let rePasswordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Re-Password..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        
        return field
    }()
    
    let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        // Continue to next field
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        
        field.backgroundColor = .secondarySystemBackground
        
        return field
    }()
    
    let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        // Continue to next field
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        
        field.backgroundColor = .secondarySystemBackground
        
        return field
    }()
    
    let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"
        
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(registerButtonTapped))
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        // Add subview
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(rePasswordField)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled =  true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePicture))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(gesture)
        
    }
    
    @objc func didTapChangeProfilePicture() {
        presentPhotoActionSheet()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: size, y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width / 2.0
        
        firstNameField.frame = CGRect(x: 30, y: imageView.bottom + 25, width: scrollView.width - 60, height: 52)
        
        lastNameField.frame = CGRect(x: 30, y: firstNameField.bottom + 20, width: scrollView.width - 60, height: 52)
        
        emailField.frame = CGRect(x: 30, y: lastNameField.bottom + 20, width: scrollView.width - 60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom + 20 , width: scrollView.width - 60, height: 52)
        
        rePasswordField.frame = CGRect(x: 30, y: passwordField.bottom + 20 , width: scrollView.width - 60, height: 52)
        
        registerButton.frame = CGRect(x: 30, y: rePasswordField.bottom + 30 , width: scrollView.width - 60, height: 52)
    }
    
    @objc func registerButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        
        let isValid = validate()
        
        if !isValid {
            alertUserLoginError()
        }
        
        guard let email = emailField.text, let password = passwordField.text else {
            return
        }
        
        spinner.show(in: view)

        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exists in
            guard !exists else {
                self?.showingAlert = true
                self?.alertMessage = "Email already exists!"
                self?.alertUserLoginError()
                return
            }
        })

        
        // Firebase Register
        if !showingAlert {
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { [weak self] authResult, error in
                
                DispatchQueue.main.async {
                    self?.spinner.dismiss()
                }
                
                guard authResult != nil, error == nil else {
                    print("Error creating User: \(String(describing: error))")
                    return
                }
                
                guard let firstName = self?.firstNameField.text, let lastName = self?.lastNameField.text else {
                    return
                }
                
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                
                DatabaseManager.shared.insertUser(with: chatUser, completion: {success in
                    if success {
                        //upload image
                        guard let image = self?.imageView.image, let data = image.pngData() else {
                            return
                        }
                        
                        UserDefaults.standard.setValue(email, forKey: "email")
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                        
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
                    }
                })
                
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Opps!", message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        present(alert, animated: true)
    }
    
//    @objc func didTapRegister() {
//        let vc = RegisterViewController()
//        vc.title = "Create Account"
//        navigationController?.pushViewController(vc, animated: true)
//    }
    
    func validate() -> Bool {
        guard let firstName = firstNameField.text, !firstName.isEmpty else {
            showingAlert = true
            alertMessage = "Please enter your Firstname"
            return false
        }
        
        guard let lastName = lastNameField.text, !lastName.isEmpty else {
            showingAlert = true
            alertMessage = "Please enter your Lastname"
            return false
        }
        
        guard let email = emailField.text, !email.isEmpty else {
            showingAlert = true
            alertMessage = "Please enter an Email"
            return false
        }
        
        guard let password = passwordField.text, !password.isEmpty else {
            showingAlert = true
            alertMessage = "Please enter a Password"
            return false
        }
        
        guard let rePassword = rePasswordField.text, !rePassword.isEmpty else {
            showingAlert = true
            alertMessage = "Please repeat your Password"
            return false
        }
        
        if !email.contains("@") && email.contains(",") && email.contains("-") {
            showingAlert = true
            alertMessage = "Please input a valid email"
            return false
        }
        
        if password.count < 6 {
            showingAlert = true
            alertMessage = "Password must contains at least 6 letters"
            return false
        }
        
        if password != rePassword {
            showingAlert = true
            alertMessage = "Your repassword does not match your password"
            return false
        }
        
        
        return true
    }
    
    
}


extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            registerButtonTapped()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate {
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture", message: "Where do you want to take picture from", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose From Library", style: .default, handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let selectedImage = info[UIImagePickerController.InfoKey.editedImage]
        self.imageView.image = selectedImage as? UIImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
    
}

