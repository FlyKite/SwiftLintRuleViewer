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
    
    private let tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        let path = "\(NSHomeDirectory())/Documents/rules.json"
        if FileManager.default.fileExists(atPath: path) {
            loadRules(at: path)
        } else {
            downloadRules(to: path)
        }
    }
    
    private func loadRules(at path: String) {
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
        RuleLoader().loadRules { (rules) in
            DispatchQueue.global().async {
                do {
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
            self.tableView.reloadData()
        }
    }
}

extension RuleListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? enabledRules.count : disabledRules.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = enabledRules[indexPath.row].name
        } else {
            cell.textLabel?.text = disabledRules[indexPath.row].name
        }
        return cell
    }
}

extension RuleListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            delegate?.ruleListControllerDidSelectRule(rule: enabledRules[indexPath.row])
        } else {
            delegate?.ruleListControllerDidSelectRule(rule: disabledRules[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Enabled Rules" : "Disabled Rules"
    }
}

extension RuleListViewController {
    private func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
