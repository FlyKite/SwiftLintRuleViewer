//
//  RuleViewController.swift
//  SwiftLintRuleViewer
//
//  Created by FlyKite on 2020/11/5.
//

import UIKit

class RuleViewController: UIViewController {
    
    var rule: Rule? { didSet { tableView.reloadData() } }
    
    private let tableView: UITableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
}

extension RuleViewController: UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rule == nil ? 0 : 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! HeaderCell
            cell.name = rule?.name
            cell.info = rule?.info
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "attribute", for: indexPath) as! AttributeCell
            let title: String
            let value: String
            switch indexPath.row {
            case 1:
                title = "Identifier"
                value = rule?.attributes.identifier ?? ""
            case 2:
                title = "Enabled by default"
                value = "\(rule?.attributes.enabledByDefault ?? false)"
            case 3:
                title = "Supports autocorrection"
                value = "\(rule?.attributes.supportsAutocorrection ?? false)"
            case 4:
                title = "Kind"
                value = rule?.attributes.kind ?? ""
            case 5:
                title = "Analyzer rule"
                value = "\(rule?.attributes.analyzerRule ?? false)"
            case 6:
                title = "Minimum Swift compiler version"
                value = rule?.attributes.minimumSwiftCompilerVersion ?? ""
            case 7:
                title = "Default configuration"
                value = rule?.attributes.defaultConfiguration ?? ""
            default:
                title = ""
                value = ""
            }
            cell.title = title
            cell.value = value
            return cell
        }
    }
}

extension RuleViewController: UITableViewDelegate {
    
}

extension RuleViewController {
    private func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HeaderCell.self, forCellReuseIdentifier: "header")
        tableView.register(AttributeCell.self, forCellReuseIdentifier: "attribute")
        tableView.tableFooterView = UIView()
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

private class HeaderCell: UITableViewCell {
    
    var name: String? {
        get { return nameLabel.text }
        set { nameLabel.text = newValue }
    }
    
    var info: String? {
        get { return infoLabel.text }
        set { infoLabel.text = newValue }
    }
    
    private let nameLabel: UILabel = UILabel()
    private let infoLabel: UILabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        
        nameLabel.font = UIFont.systemFont(ofSize: 36, weight: .semibold)
        
        infoLabel.font = UIFont.systemFont(ofSize: 18)
        infoLabel.numberOfLines = 0
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(infoLabel)
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(48)
            make.left.equalToSuperview().offset(15)
        }
        
        infoLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.top.equalTo(nameLabel.snp.bottom).offset(24)
            make.right.lessThanOrEqualToSuperview().offset(-15)
            make.bottom.equalToSuperview().offset(-36)
        }
    }
}

private class AttributeCell: UITableViewCell {
    
    var title: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var value: String? {
        get { return valueLabel.text }
        set { valueLabel.text = newValue }
    }
    
    private let titleLabel: UILabel = UILabel()
    private let valueLabel: UILabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        selectionStyle = .none
        
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        valueLabel.numberOfLines = 0
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
            make.right.lessThanOrEqualTo(valueLabel.snp.left)
            make.width.greaterThanOrEqualToSuperview().multipliedBy(0.3)
        }
        
        valueLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-15)
            make.top.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
        }
    }
}
