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
        self.viewControllers = [listController, ruleController]
    }
}

extension ViewController: RuleListViewControllerDelegate {
    func ruleListControllerDidSelectRule(rule: Rule) {
        ruleController.rule = rule
    }
}
