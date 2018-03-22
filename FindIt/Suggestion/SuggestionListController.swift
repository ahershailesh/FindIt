//
//  SuggestionListController.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/17/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

class SuggestionListController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var dataHandler: SuggestionDataHandler? {
        didSet {
            dataHandler?.notifier = self
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor.clear
        view.backgroundColor = UIColor.clear
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setupTableView() {
        registerCells()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.tableHeaderView = dataHandler?.getTableHeaderView()
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: "SuggestionTableViewCell", bundle: nil), forCellReuseIdentifier: String(describing: SuggestionTableViewCell.self))
    }
    
}

extension SuggestionListController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let handler = dataHandler, handler.shouldShowHeader(forPage: section) else {
            let headerView = UIView(frame: .zero)
            return headerView
        }
        let headerView = SuggestionHeaderView(frame: CGRect(x: 0, y: 0, width: 80, height: 24))
        headerView.label.text = handler.getTitle(forPage: section)
        return headerView
        
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataHandler?.getNumberOfPages() ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataHandler?.getSuggestions(forPage: section).count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SuggestionTableViewCell.self)) as? SuggestionTableViewCell
        cell?.suggesion = dataHandler?.getSuggestion(atIndexPath: indexPath)
        return cell ?? UITableViewCell()
    }
}

extension SuggestionListController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? SuggestionTableViewCell, let suggestion = cell.suggesion, dataHandler?.shouldSelect(suggestion: suggestion, indexPath: indexPath) ?? false {
            dataHandler?.didSelected(suggestion: suggestion, atIndexPath: indexPath)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        dataHandler?.tableViewScrolled(scrollView: scrollView)
    }
}

extension SuggestionListController : SuggestionNotifier {
    func refreshSuggestions() {
        tableView.reloadData()
    }
    
    func showTopSuggestions() {
        UIView.animate(withDuration: 0.5) {
            self.tableView.contentOffset = .zero
        }
    }
}
