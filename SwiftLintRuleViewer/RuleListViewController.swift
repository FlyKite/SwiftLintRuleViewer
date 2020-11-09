//
//  RuleListViewController.swift
//  SwiftLintRuleViewer
//
//  Created by FlyKite on 2020/11/5.
//

import UIKit
import SnapKit

struct Rule: Codable {
    var name: String
    var info: String
    var attributes: Attributes
    var nonTriggeringExamples: [String]
    var triggeringExamples: [String]
    
    struct Attributes: Codable {
        var identifier: String
        var enabledByDefault: Bool
        var supportsAutocorrection: Bool
        var kind: String
        var analyzerRule: Bool
        var minimumSwiftCompilerVersion: String
        var defaultConfiguration: String
    }
}

protocol RuleListViewControllerDelegate: AnyObject {
    func ruleListControllerDidSelectRule(rule: Rule)
}

class RuleListViewController: UIViewController {
    
    weak var delegate: RuleListViewControllerDelegate?
    
    private var enabledRules: [Rule] = []
    private var disabledRules: [Rule] = []
    
    private var showSearchResult: Bool = false
    private var enabledSearchResult: [Rule] = []
    private var disabledSearchResult: [Rule] = []
    
    private let tableView: UITableView = UITableView()
    private let searchBar: UISearchBar = UISearchBar()
    private let loadingView: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)
    private let loadingLabel: UILabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadingView.startAnimating()
        loadingView.isHidden = false
        loadingLabel.isHidden = false
        loadingLabel.text = "正在加载..."
        tableView.isHidden = true
        let path = "\(NSHomeDirectory())/Documents/rules.json"
        if FileManager.default.fileExists(atPath: path) {
            loadRules(at: path)
        } else {
            downloadRules(to: path)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    private func loadRules(at path: String) {
        loadingLabel.text = "正在加载..."
        DispatchQueue.global().async {
            do {
                let url = URL(fileURLWithPath: path)
                let data = try Data(contentsOf: url)
                let rules = try JSONDecoder().decode([Rule].self, from: data)
                self.handleRules(rules: rules)
            } catch {
                print(error)
            }
        }
    }
    
    private func downloadRules(to path: String) {
        RuleLoader().loadRules { (progress) in
            DispatchQueue.main.async {
                switch progress {
                case .loadingList:
                    self.loadingLabel.text = "正在加载目录..."
                case let .loadingRules(count, totalCount):
                    self.loadingLabel.text = "\(count)/\(totalCount)"
                }
            }
        } completion: { (rules) in
            DispatchQueue.global().async {
                do {
                    guard !rules.isEmpty else { return }
                    self.handleRules(rules: rules)
                    let data = try JSONEncoder().encode(rules)
                    try data.write(to: URL(fileURLWithPath: path))
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private func handleRules(rules: [Rule]) {
        self.enabledRules = rules.filter { $0.attributes.enabledByDefault }
        self.disabledRules = rules.filter { !$0.attributes.enabledByDefault }
        DispatchQueue.main.async {
            self.loadingView.stopAnimating()
            self.loadingView.isHidden = true
            self.loadingLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

extension RuleListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showSearchResult {
            return section == 0 ? enabledSearchResult.count : disabledSearchResult.count
        } else {
            return section == 0 ? enabledRules.count : disabledRules.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let rule: Rule
        if showSearchResult {
            rule = indexPath.section == 0 ? enabledSearchResult[indexPath.row] : disabledSearchResult[indexPath.row]
        } else {
            rule = indexPath.section == 0 ? enabledRules[indexPath.row] : disabledRules[indexPath.row]
        }
        cell.textLabel?.text = rule.name
        return cell
    }
}

extension RuleListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rule: Rule
        if showSearchResult {
            rule = indexPath.section == 0 ? enabledSearchResult[indexPath.row] : disabledSearchResult[indexPath.row]
        } else {
            rule = indexPath.section == 0 ? enabledRules[indexPath.row] : disabledRules[indexPath.row]
        }
        delegate?.ruleListControllerDidSelectRule(rule: rule)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Enabled Rules" : "Disabled Rules"
    }
}

extension RuleListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchBar.text?.lowercased(), !text.isEmpty else {
            showSearchResult = false
            tableView.reloadData()
            return
        }
        showSearchResult = true
        DispatchQueue.global().async {
            self.enabledSearchResult = self.enabledRules.filter { (rule) in
                return rule.name.lowercased().contains(text) || rule.attributes.identifier.contains(text)
            }
            self.disabledSearchResult = self.disabledRules.filter { (rule) in
                return rule.name.lowercased().contains(text) || rule.attributes.identifier.contains(text)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension RuleListViewController {
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag
        
        searchBar.delegate = self
        
        loadingLabel.font = UIFont.systemFont(ofSize: 16)
        
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(loadingView)
        view.addSubview(loadingLabel)
        
        searchBar.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(searchBar.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
        
        loadingView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-80)
        }
        
        loadingLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(loadingView.snp.bottom).offset(12)
        }
    }
}
