//
//  RuleLoader.swift
//  SwiftLintRuleViewer
//
//  Created by FlyKite on 2020/11/5.
//

import Alamofire
import SwiftSoup

class RuleLoader {
    
    private let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
    
    func loadRules(completion: @escaping ([Rule]) -> Void) {
        loadRuleList { (result) in
            DispatchQueue.global().async {
                var rules: [Rule] = []
                switch result {
                case let .success(list):
                    for item in list {
                        guard let url = URL(string: "https://realm.github.io/SwiftLint/\(item.url)") else { continue }
                        self.loadRule(url: url) { (result) in
                            switch result {
                            case let .success(rule):
                                rules.append(rule)
                            case let .failure(error):
                                print(error)
                            }
                            self.semaphore.signal()
                        }
                        self.semaphore.wait()
                    }
                case let .failure(error):
                    print(error)
                }
                completion(rules)
            }
        }
    }
    
    private func loadRule(url: URL, completion: @escaping (Result<Rule, Error>) -> Void) {
        let request = AF.request(url).responseString { (response) in
            switch response.result {
            case let .success(html):
                DispatchQueue.global().async {
                    do {
                        let rule = try self.handleRule(html: html)
                        completion(.success(rule))
                    } catch {
                        completion(.failure(error))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
        request.resume()
    }
    
    private func handleRule(html: String) throws -> Rule {
        let doc = try SwiftSoup.parse(html)
        guard let content = try doc.select("div.section-content").first() else {
            throw NSError(domain: "Section not found", code: -9999, userInfo: nil)
        }
        let name = (try content.getElementsByTag("h1").first()?.text()) ?? ""
        let info = (try content.getElementsByTag("p").first()?.text()) ?? ""
        var attributes: [String: Any] = [:]
        if let list = try content.getElementsByTag("ul").first()?.getElementsByTag("li") {
            for item in list {
                let name = (try item.getElementsByTag("strong").first()?.text().replacingOccurrences(of: ":", with: "")) ?? ""
                let key = handleAttributeKey(key: name)
                let value = item.textNodes().first?.text().trimmingCharacters(in: CharacterSet(charactersIn: " ")) ?? ""
                switch key {
                case "enabledByDefault":
                    attributes[key] = value == "Enabled"
                case "supportsAutocorrection", "analyzerRule":
                    attributes[key] = value == "Yes"
                default:
                    attributes[key] = value
                }
            }
        }
        let data = try JSONSerialization.data(withJSONObject: attributes, options: [])
        let detailAttributes = try JSONDecoder().decode(Rule.Attributes.self, from: data)
        
        var nonTriggeringExamples: [String] = []
        var triggeringExamples: [String] = []
        let nodes = content.children()
        var index = 4
        var isTriggering = false
        while index < nodes.count {
            let node = nodes.get(index)
            if node.tagName() == "h2" {
                isTriggering = true
            } else if node.tagName() == "pre" {
                if isTriggering {
                    triggeringExamples.append(try node.html())
                } else {
                    nonTriggeringExamples.append(try node.html())
                }
            }
            index += 1
        }
        
        return Rule(name: name,
                    info: info,
                    attributes: detailAttributes,
                    nonTriggeringExamples: nonTriggeringExamples,
                    triggeringExamples: triggeringExamples)
    }
    
    private func handleAttributeKey(key: String) -> String {
        let components = key.components(separatedBy: " ")
        var newKey = ""
        if components.count > 1 {
            newKey = components[0].lowercased()
            for index in 1 ..< components.count {
                let item = components[index]
                if let first = item.first {
                    newKey.append(String(first).uppercased())
                }
                let tail = String(item.dropFirst())
                newKey.append(tail)
            }
        } else if let first = components.first {
            newKey = first.lowercased()
        }
        return newKey
    }
    
    private struct RuleItem {
        var name: String
        var url: String
    }

    private func loadRuleList(completion: @escaping (Result<[RuleItem], Error>) -> Void) {
        let url = URL(string: "https://realm.github.io/SwiftLint/rule-directory.html")!
        let request = AF.request(url).responseString { (response) in
            switch response.result {
            case let .success(html):
                DispatchQueue.global().async {
                    do {
                        let rules = try self.handleRuleList(html: html)
                        completion(.success(rules))
                    } catch {
                        completion(.failure(error))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
        request.resume()
    }
    
    private func handleRuleList(html: String) throws -> [RuleItem] {
        let doc = try SwiftSoup.parse(html)
        guard let list = try doc.select("section.section").select("ul").first()?.select("li") else {
            throw NSError(domain: "Section not found", code: -9999, userInfo: nil)
        }
        var rules: [RuleItem] = []
        for item in list {
            guard let link = try item.getElementsByTag("a").first() else { continue }
            let name = try link.text()
            let url = try link.attr("href")
            rules.append(RuleItem(name: name, url: url))
        }
        return rules
    }
    
}
