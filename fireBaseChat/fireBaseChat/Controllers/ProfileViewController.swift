//
//  ProfileViewController.swift
//  fireBaseChat
//
//  Created by Anton on 09.05.2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Log Out"]
    
    //MARK: - View did load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        
    }
    
//MARK: - Picture in the profile
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String  else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 300))
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("An error occured: failed to get download url.  \(error)")
            }
            
        })
        
        return headerView
    }
    
    //MARK: - Download an image
    
    func downloadImage(imageView: UIImageView, url: URL) {
        
        URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
    }
    
}

//MARK: Table view delegate and datasource

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Number of rows initialize
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    //MARK: - Cell initialize
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = data[indexPath.row]
        
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        
        return cell
    }
    
    //MARK: - Row was selected
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        logOut()
    }
    
    //MARK: - Log out
    
    func logOut() {
        
        let actionSheet = UIAlertController(title: "Log out?",
                                            message: "Are you sure you want to log out?",
                                            preferredStyle: .alert)
        actionSheet.addAction(UIAlertAction(title: "Yes",
                                            style: .destructive,
                                            handler: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            //Log out facebook
            
            FBSDKLoginKit.LoginManager().logOut()
            
            //Log out Google
            
            GIDSignIn.sharedInstance.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                print("Log out succesfull")
                
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: true)
                
                
            } catch {
                print("Failed to log out...")
            }
            
        }))
        actionSheet.addAction(UIAlertAction(title: "No",
                                            style: .default,
                                            handler: { _ in
            actionSheet.dismiss(animated: true)
        }))
        present(actionSheet, animated: true)
    }
}

