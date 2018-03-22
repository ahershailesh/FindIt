//
//  SuggestionDataHandler.swift
//  FindIt
//
//  Created by Shailesh Aher on 3/17/18.
//  Copyright © 2018 Shailesh Aher. All rights reserved.
//

import UIKit

/*
 PresentingController  <->  SuggestionDataHadler   <->  PresentedController
 */

/*
 Who should implement this:- The handler which will going to provide data to show suggestion.
 Why should implement this:- Handler will have sole responsibility of managing data. The handler will be the only one who will decide which data to show at which time.
 Who should call this:- The presented controller with presentation logic.
 */
//MARK:- Suggestion DataSource -
protocol SuggestionDataSource {
    /// If the presenting controller has section based presentation logic, PresentedController will call this method to know how many sections to present.
    ///
    /// - Returns: number of pages to display
    func getNumberOfPages() -> Int
    
    
    /// If the presenting controller has section based presentation logic, PresentedController will call this method to know section title.
    ///
    /// - Parameter page: page index.
    /// - Returns: section title in string format.
    func getTitle(forPage page: Int) -> String
    func getSuggestions(forPage page: Int) -> [Suggestion]
    func getSuggestion(atIndexPath indexPath: IndexPath) -> Suggestion
}


/*
 Who should implement this:- The controller which is presented.
 Why should implement this:- to know when to refresh data.
 Who should call this:- The handler which is managing data.
 */
//MARK:- Suggestion Notifier -
protocol SuggestionNotifier {
    /// if data handler got new suggestions or deleted some of the data, or just wanted to make changes in data shown to the user, handler will call this method
    func refreshSuggestions()
    func showTopSuggestions()
}

/*
 Who should implement this:- The presenting controller.
 Why should implement this:- to get the events which presented controller is providing and to provide premission for further actions.
 Who should call this:- The controller with presentation logic.
 */
//MARK:- Suggestion CallBacks -
@objc protocol SuggestionCallBacks {
    
    /// Get the permission for further action on suggestion selection
    ///
    /// - Parameters:
    ///   - suggestion: suggestion that is selected
    ///   - indexPath: indexPath for selected Item
    /// - Returns: permission for further action.
    func shouldSelect(suggestion: Suggestion, indexPath: IndexPath) -> Bool
    func didSelected(suggestion: Suggestion, atIndexPath indexPath: IndexPath)
    func shouldShowHeader(forPage page: Int) -> Bool
    func tableViewScrolled(scrollView: UIScrollView)
    func getTableHeaderView() -> UIView?
}

protocol SuggestionErrorProtocol {
    func pageNotFound(page: Int)
}

extension SuggestionErrorProtocol {
    func pageNotFound(page: Int) {
        fatalError("we don't have any page at index \(page)")
    }
}

//MARK:- SuggestionDataHandler
class SuggestionDataHandler: NSObject {
    
    private var suggestionList : [[Suggestion]]
    var callBack : SuggestionCallBacks?
    var notifier : SuggestionNotifier?
    var errorHandler : SuggestionErrorProtocol?
    
    override init() {
        suggestionList = []
        super.init()
    }
    
    convenience init(suggestions : [Suggestion]) {
        self.init()
        suggestionList = [suggestions]
    }
    
    private func handlerNoPageError(forPage page: Int) {
        if !suggestionList.indices.contains(page) {
            errorHandler?.pageNotFound(page: page)
        }
    }
    
    
    // MARK: - Public functions
    func addSuggestions(suggestions : [Suggestion]) {
        if !suggestions.isEmpty {
            suggestionList.insert(suggestions, at: 0)
        }
        notifier?.refreshSuggestions()
    }
    
    func showTopSuggestions() {
        notifier?.showTopSuggestions()
    }
}

/*
 Presented controller facing implemetation
 */
extension SuggestionDataHandler : SuggestionDataSource {
    
    func getSuggestion(atIndexPath indexPath: IndexPath) -> Suggestion {
        return suggestionList[indexPath.section][indexPath.row]
    }
    
    func getNumberOfPages() -> Int {
        return suggestionList.count
    }
    
    func getTitle(forPage page: Int) -> String {
        handlerNoPageError(forPage: page)
        return "\(page)"
    }
    
    func getSuggestions(forPage page: Int) -> [Suggestion] {
        handlerNoPageError(forPage: page)
        return suggestionList[page]
    }
}

extension SuggestionDataHandler : SuggestionCallBacks {
    func shouldShowHeader(forPage page: Int) -> Bool {
        return callBack?.shouldShowHeader(forPage: page) ?? false
    }
    
    func shouldSelect(suggestion: Suggestion, indexPath: IndexPath) -> Bool {
        return callBack?.shouldSelect(suggestion: suggestion, indexPath: indexPath) ?? false
    }
    
    func tableViewScrolled(scrollView: UIScrollView) {
        callBack?.tableViewScrolled(scrollView: scrollView)
    }
    
    func getTableHeaderView() -> UIView? {
        return callBack?.getTableHeaderView()
    }
    
    func didSelected(suggestion: Suggestion, atIndexPath indexPath: IndexPath) {
        callBack?.didSelected(suggestion: suggestion, atIndexPath: indexPath)
    }
}
