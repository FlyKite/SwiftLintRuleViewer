//
//  RuleViewController.swift
//  SwiftLintRuleViewer
//
//  Created by FlyKite on 2020/11/5.
//

import UIKit
import SwiftSoup

class RuleViewController: UIViewController {
    
    var rule: Rule? { didSet { updateRule() } }
    
    private let tableView: UITableView = UITableView()
    
    private var attributes: [(name: String, value: String)] = []
    private var nonTriggeringExamples: [NSAttributedString] = []
    private var triggeringExamples: [NSAttributedString] = []
    
    private static var keys: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func updateRule() {
        guard let rule = rule else { return }
        DispatchQueue.global().async {
            self.attributes = [
                ("Identifier", rule.attributes.identifier),
                ("Enabled by default", "\(rule.attributes.enabledByDefault)"),
                ("Supports autocorrection", "\(rule.attributes.supportsAutocorrection)"),
                ("Kind", rule.attributes.kind),
                ("Analyzer rule", "\(rule.attributes.analyzerRule)"),
                ("Minimum Swift compiler version", rule.attributes.minimumSwiftCompilerVersion),
                ("Default configuration", rule.attributes.defaultConfiguration),
            ]
            self.nonTriggeringExamples = rule.nonTriggeringExamples.map(self.handleHtml)
            self.triggeringExamples = rule.triggeringExamples.map(self.handleHtml)
            DispatchQueue.main.async {
                guard self.rule?.attributes.identifier == rule.attributes.identifier else { return }
                self.tableView.reloadData()
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
    
    private func handleHtml(html: String) -> NSAttributedString {
        do {
            let doc = try SwiftSoup.parse(html)
            guard let code = try doc.getElementsByTag("code").first() else { return NSAttributedString() }
            let attrText = NSMutableAttributedString()
            for node in code.getChildNodes() {
                if let node = node as? TextNode {
                    attrText.append(NSAttributedString(string: node.getWholeText()))
                } else if let node = node as? Element {
                    let className = try node.className()
                    if let attributes = style[className] {
                        attrText.append(NSAttributedString(string: try node.text(), attributes: attributes))
                    } else {
                        attrText.append(NSAttributedString(string: try node.text()))
                    }
                } else {
                    print(node)
                }
            }
            return attrText
        } catch {
            print(error)
            return NSAttributedString()
        }
    }
    
    private let style: [String: [NSAttributedString.Key: Any]] = [
        "k": [.foregroundColor: UIColor(hex: 0xE12DA0)],
        "kc": [.foregroundColor: UIColor(hex: 0xE12DA0)],
        "s": [.foregroundColor: UIColor(hex: 0xDE3A3C)],
//        "se",
//        "mb",
        "nf": [.foregroundColor: UIColor(hex: 0x18B5B1)],
        "nv": [.foregroundColor: UIColor(hex: 0x18B5B1)],
        "cp": [.foregroundColor: UIColor(hex: 0xE12DA0)],
        "c1": [.foregroundColor: UIColor(hex: 0x51C34F)],
        "kt": [.foregroundColor: UIColor(hex: 0x6BDFFF)],
//        "mh",
        "kd": [.foregroundColor: UIColor(hex: 0xD7008F)],
        "mf": [.foregroundColor: UIColor(hex: 0x00AAA3)],
//        "n",
        "mi": [.foregroundColor: UIColor(hex: 0x00AAA3)],
//        "p",
//        "o",
        "cm": [.foregroundColor: UIColor(hex: 0x51C34F)],
        "err": [.backgroundColor: UIColor.systemGray4, .foregroundColor: UIColor.systemRed],
//        "mo"
    ]
    
}

extension RuleViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return attributes.count
        case 2: return nonTriggeringExamples.count == 0 ? 0 : nonTriggeringExamples.count + 1
        case 3: return triggeringExamples.count == 0 ? 0 : triggeringExamples.count + 1
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! HeaderCell
            cell.name = rule?.name
            cell.info = rule?.info
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "attribute", for: indexPath) as! AttributeCell
            cell.title = attributes[indexPath.row].name
            cell.value = attributes[indexPath.row].value
            return cell
        case 2:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "exampleHeader", for: indexPath) as! ExampleHeaderCell
                cell.title = "Non Triggering Examples"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "example", for: indexPath) as! ExampleCell
                cell.attributedText = nonTriggeringExamples[indexPath.row - 1]
                return cell
            }
        case 3:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "exampleHeader", for: indexPath) as! ExampleHeaderCell
                cell.title = "Triggering Examples"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "example", for: indexPath) as! ExampleCell
                cell.attributedText = triggeringExamples[indexPath.row - 1]
                return cell
            }
        default:
            fatalError()
        }
    }
}

extension RuleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let attrText: NSAttributedString?
        if indexPath.section == 2 && indexPath.row > 0 {
            attrText = nonTriggeringExamples[indexPath.row - 1]
        } else if indexPath.section == 3 && indexPath.row > 0 {
            attrText = triggeringExamples[indexPath.row - 1]
        } else {
            attrText = nil
        }
        guard let text = attrText else {
            return UITableView.automaticDimension
        }
        let bounds = text.boundingRect(with: CGSize(width: view.bounds.width - 64, height: CGFloat(MAXFLOAT)),
                                       options: [.usesFontLeading, .usesLineFragmentOrigin],
                                       context: nil)
        return ceil(bounds.height) + 48
    }
}

extension RuleViewController {
    private func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HeaderCell.self, forCellReuseIdentifier: "header")
        tableView.register(AttributeCell.self, forCellReuseIdentifier: "attribute")
        tableView.register(ExampleCell.self, forCellReuseIdentifier: "example")
        tableView.register(ExampleHeaderCell.self, forCellReuseIdentifier: "exampleHeader")
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 24))
        
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
        nameLabel.numberOfLines = 0
        
        infoLabel.font = UIFont.systemFont(ofSize: 18)
        infoLabel.numberOfLines = 0
        
        let separator = UIView()
        separator.backgroundColor = .systemGray3
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(separator)
        
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(48)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        
        infoLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(nameLabel.snp.bottom).offset(24)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-36)
        }
        
        separator.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(1)
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
        
        let separator = UIView()
        separator.backgroundColor = .systemGray3
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(separator)
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.right.lessThanOrEqualTo(valueLabel.snp.left)
            make.width.greaterThanOrEqualToSuperview().multipliedBy(0.3)
        }
        
        valueLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        separator.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(1)
        }
    }
}

private class ExampleHeaderCell: UITableViewCell {
    
    var title: String? {
        get { return label.text }
        set { label.text = newValue }
    }
    
    private let label: UILabel = UILabel()
    
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
        
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        
        contentView.addSubview(label)
        
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(24)
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
}

private class ExampleCell: UITableViewCell {
    
    var attributedText: NSAttributedString? {
        get { return label.attributedText }
        set { label.attributedText = newValue }
    }
    
    private let container: UIView = UIView()
    private let label: UILabel = UILabel()
    
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
        
        container.backgroundColor = UIColor(hex: 0x292B36)
        container.layer.cornerRadius = 8
        
        label.font = UIFont(name: "AndaleMono", size: 20)
        label.numberOfLines = 0
        
        contentView.addSubview(container)
        container.addSubview(label)
        
        container.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
}
