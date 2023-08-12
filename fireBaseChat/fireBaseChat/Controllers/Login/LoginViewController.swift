//
//  LoginViewController.swift
//  fireBaseChat
//
//  Created by Anton on 09.05.2023.
//

import UIKit
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD


class LoginViewController: UIViewController {
    
    //MARK: - Initialize views
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        
        scrollView.clipsToBounds = true
        
        return scrollView
    }()
    
    private let textHelloView: UITextView = {
        let textHelloView = UITextView()
        textHelloView.contentMode = .scaleAspectFit
        textHelloView.text = "Hello Again!"
        textHelloView.font = .boldSystemFont(ofSize: 30)
        textHelloView.clipsToBounds = true
        textHelloView.isUserInteractionEnabled = false
        
        
        return textHelloView
    }()
    
    
    private let emailField: UITextField = {
        let field = UITextField()
        
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 6
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.layer.borderColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
        field.placeholder = "Email Adress..."
        field.backgroundColor = .secondarySystemBackground
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 6
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.backgroundColor = .secondarySystemBackground
        field.layer.borderColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.isSecureTextEntry = true
        
        return field
    }()
    
    private let logInButton: UIButton = {
        let button = UIButton()
        
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.borderColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
        
        
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        
        button.permissions = ["email", "public_profile"]
        
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        
        button.style = .wide
        button.colorScheme = .light
        
        return button
    }()
    
    //MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.self.backgroundColor = .systemBackground
        title = "Log in"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        
        logInButton.addTarget(self,
                              action: #selector(didTapLogIn),
                              for: .touchUpInside)
        
        googleLoginButton.addTarget(self,
                                    action: #selector(didTapGoogleLoginButton),
                                    for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        
        //MARK: Add subviews
        
        view.addSubview(scrollView)
        scrollView.addSubview(textHelloView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(logInButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    //MARK: - Layout
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        textHelloView.frame = CGRect(x: ((scrollView.width - size) / 2) - 15,
                                     y: 30,
                                     width: scrollView.width - 60,
                                     height: size)
        emailField.frame = CGRect(x: 30,
                                  y: textHelloView.bottom + 30,
                                  width: scrollView.width - 60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 30,
                                     width: scrollView.width - 60,
                                     height: 52)
        logInButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 30,
                                   width: scrollView.width - 60,
                                   height: 52)
        facebookLoginButton.frame = CGRect(x: 30,
                                           y: logInButton.bottom + 30,
                                           width: scrollView.width - 60,
                                           height: 52)
        
        facebookLoginButton.frame.origin.y = logInButton.bottom + 30
        
        googleLoginButton.frame = CGRect(x: 30,
                                         y: facebookLoginButton.bottom + 5,
                                         width: scrollView.width - 60,
                                         height: 52)
    }
    
    
    //MARK: Functions
    //MARK: - Log in button function
    @objc private func didTapLogIn() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            
            alertUserLogInError()
            return
        }
        
        spinner.show(in: view)
        
        //MARK:  Firebase log in
        FirebaseAuth.Auth.auth().signIn(withEmail: email,
                                        password: password,
                                        completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Error while signing in...")
                return
            }
            
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                    
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String
                    else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    UserDefaults.standard.set(email, forKey: "email")

                case .failure(let error):
                    print("An error occured. Failed to read data with error: \(error)")
                }
            })
            
            

            
            print("Logged in User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true,
                                                     completion: nil)
            
        })
    }
    
    
    //MARK: - Google log in button
    
    @objc private func didTapGoogleLoginButton() {
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            guard error == nil else {
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                return
            }
            
            guard let email = user.profile?.email,
                  let firstName = user.profile?.givenName,
                  let lastName = user.profile?.familyName
            else {
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName ,
                                               emailAddress: email)
                    
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            //upload image
                            
                            if user.profile?.hasImage == true {
                                guard let url = user.profile?.imageURL(withDimension: 200) else {
                                    return
                                }
                                
                                
                                URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                    guard let data = data else {
                                        return
                                    }
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                        switch result {
                                        case .success(let downloadURL):
                                            UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                            print(downloadURL)
                                        case .failure(let error):
                                            print("An error occured: \(error)")
                                        }
                                    })
                                }).resume()
                            }
                            
                        }
                    })
                }
                
            })
            
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            FirebaseAuth.Auth.auth().signIn(with: credential,
                                            completion: { [weak self] authResult, error in
                guard authResult != nil, error == nil else {
                    print("Google credential log in failed...")
                    print("MFA may be needed...")
                    return
                }
                guard let strongSelf = self else {
                    return
                }
                print("Succesfully logged in via Google...")
                strongSelf.navigationController?.dismiss(animated: true,
                                                         completion: nil)
            })
        }
        
    }
    
    //MARK: - Alert error during log in
    func alertUserLogInError() {
        let alert = UIAlertController(title: "Whoops...",
                                      message: "Something went wrong, please make sure that both email and password are filled in. Also make sure that password is more than 6 symbols long",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Got it!",
                                      style: .cancel,
                                      handler: nil))
        
        present(alert, animated: true)
    }
    
    //MARK: - Register button function
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

//MARK: -  Extensions
extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            didTapLogIn()
        }
        
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    
    //MARK: Facebook log in
    
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: Error?) {
        
        // Unwrap a token from Facebook
        guard let token = result?.token?.tokenString else {
            print("User faield to log in with Facebook...")
            return
        }
        
        // Make a request to get data about the user
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" : "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        // Execute a request
        facebookRequest.start(completion: { _, result, error in
            
            guard let result = result as? [String: Any],
                  error == nil else {
                print("Failed to make facebook graph request...")
                return
            }
            
            print("\(result)")
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String
            else {
                print("Failed to get email and name from FBResults...")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName ,
                                               emailAddress: email)
                    
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            //upload image
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            print("Downloading data from facebook image")
                            
                            URLSession.shared.dataTask(with: url, completionHandler:  { data, _, _ in
                                guard let data = data else {
                                    print("An error occured: Failed to get data from facebook")
                                    return
                                }
                                //upload image
                                print("Successfully downloaded data from facebook image, uploading to DB")
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName, completion: { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                        print(downloadURL)
                                    case .failure(let error):
                                        print("An error occured: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
            })
            
            
            //  Signing in via Firebase using Facebook credentials
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential,
                                            completion: { [weak self] authResult, error in
                guard authResult != nil, error == nil else {
                    print("Facebook credential log in failed...")
                    print("MFA may be needed...")
                    return
                }
                guard let strongSelf = self else {
                    return
                }
                print("Succesfully logged in via Facebook...")
                strongSelf.navigationController?.dismiss(animated: true,
                                                         completion: nil)
            })
        })
        
        
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // no operation
    }
}



