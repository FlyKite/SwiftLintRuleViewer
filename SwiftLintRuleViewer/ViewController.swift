//
//  ViewController.swift
//  SwiftLintRuleViewer
//
//  Created by FlyKite on 2020/11/5.
//

import UIKit

class ViewController: UISplitViewController {
    
    private let listController: RuleListViewController = RuleListViewController()
    private let ruleController: RuleViewController = RuleViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        listController.delegate = self
        self.viewControllers = [UINavigationController(rootViewController: listController)]
    }
}

extension ViewController: RuleListViewControllerDelegate {
    func ruleListControllerDidSelectRule(rule: Rule) {
        ruleController.rule = rule
        listController.showDetailViewController(ruleController, sender: nil)
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
