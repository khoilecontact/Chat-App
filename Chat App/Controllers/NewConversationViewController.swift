//
//  NewConversationViewController.swift
//  Chat App
//
//  Created by KhoiLe on 30/08/2021.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    private var hasFetched = false
    
    private var results = [[String: String]]()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Seatch for Users..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
       let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.isHidden = true
        return tableView
    }()
    
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true 
        label.text = "No result"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        view.backgroundColor = .white
        
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width / 4, y: (view.height - 200) / 2, width: view.width / 2, height: 200)
    }
    
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }

        searchBar.resignFirstResponder()

        results.removeAll()
        spinner.show(in: view)

        self.searchUser(query: text)
    }
    
    
    func searchUser(query: String) {
        // check if array has firebase result
        if hasFetched {
            // if it does: filter
            filterUser(with: query)
        } else {
        // if not, fetch and filter
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUser(with: query)
                case .failure(let error):
                    print("Failed to get users collections: \(error)")
                }
            })
        }
    }
    
    func filterUser(with term: String) {
        guard hasFetched else {
            return
        }
        
        self.spinner.dismiss()
        
        // this is a loop
        let results: [[String: String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = results
        
        updateUI()
    }
    
    func updateUI() {
        if results.isEmpty {
            self.noResultLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation
    }
}
