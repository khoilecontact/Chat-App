//
//  ProfileViewController.swift
//  Chat App
//
//  Created by KhoiLe on 30/08/2021.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage


enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: () -> Void
}

var data = [ProfileViewModel]()

class ProfileViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.indetifier)
        
        data.append(ProfileViewModel(viewModelType: .info, title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")", handler: {}))
        data.append(ProfileViewModel(viewModelType: .info, title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")", handler: {}))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log out", handler: { [weak self] in
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
                
                // Log out Facebook
                FBSDKLoginKit.LoginManager().logOut()
                
                //Log out Google
                GIDSignIn.sharedInstance.signOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let vc = LoginViewController()
                    // Create a navigation controller
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen

                    self?.present(nav, animated: true)
                } catch {
                    print("Error in signing out")
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self?.present(actionSheet, animated: true)
        }))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email as! String)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 250))
        headerView.backgroundColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 0)
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2, y: 45, width: 150, height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        headerView.addSubview(imageView)
        
        storageManager.shared.downloadUrl(for: path, completion: { result in
            switch result {
            case .failure(let error):
                print("Failed to download URL: \(error)")
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            }
        })
        
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL) {
        imageView.sd_setImage(with: url, completed: nil)
//        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
//            guard let data = data, error == nil else { return }
//
//            DispatchQueue.main.async {
//                let image = UIImage(data: data)
//                imageView.image = image
//            }
//        }).resume()
    }

}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.indetifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler()
    }
}

class ProfileTableViewCell: UITableViewCell {
    static let indetifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            self.textLabel?.textAlignment = .left
            self.selectionStyle = .none
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
    }
}
