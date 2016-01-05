//
//  NoteTableViewController.swift
//  MobileBackendIOS
//
//  Created by Huang, Greg on 11/8/15.
//  Copyright © 2015 Amazon Web Services. All rights reserved.
//

import UIKit

class NoteTableViewController: UITableViewController, UISearchResultsUpdating{
    
    //var notes: Array<Note> = [Note(noteId:"123", headline:"first", text:"Hello wold"),
    //Note(noteId:"456456", headline:"second", text:"also hello world")]
    
    var notes: Array<Note> = []

    @IBOutlet weak var table: UITableView!
    var resultSearchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.resultSearchController = UISearchController(searchResultsController: nil)
        self.resultSearchController.searchResultsUpdater = self
        self.resultSearchController.dimsBackgroundDuringPresentation = false
        self.resultSearchController.searchBar.sizeToFit()
        self.resultSearchController.searchBar.placeholder = "搜索"
        
        self.tableView.tableHeaderView = self.resultSearchController.searchBar
        
        MobileBackendApi.sharedInstance.configureNoteApi()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        return self.notes.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! tableViewCell
        
        
        let note = self.notes[indexPath.row]
        
        print(CouldfrontURL + note.s3key!)
        MobileBackendApi.sharedInstance.downloadImage(CouldfrontURL + "resized-" + note.s3key!, imageURL: cell.imageViewSmall)
        
        
        cell.titleLabel.text = note.headline
        cell.contentLabel.text = note.text

        return cell
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        if searchController.searchBar.text!.characters.count > 2 {
            self.notes.removeAll()
            self.search(searchController.searchBar.text!)

        }
    }
    
    func search(text: String) -> Void {
        MobileBackendApi.sharedInstance.searchNotes(text).continueWithBlock{(task) -> AnyObject! in
            var notes = [Note]()
            
            if let error = task.error {
                print("Failed search notes: [\(error)]")
                
            }
            if let exception = task.exception {
                print("Failed search notes: [\(exception)]")
            }
            if let noteResponse = task.result as? APISearchNoteResponse{
                if((noteResponse.success) != nil) {
                    
                    print("Searched note successfully")
                    for(var i=0;i<noteResponse.notes.count;i++){
                        notes.append(Note(noteId : noteResponse.notes[i].noteId, headline: noteResponse.notes[i].headline, text:noteResponse.notes[i]._text, s3key: noteResponse.notes[i].s3key))
                    }
                    
                    
                }else {
                    print("Faild search notes due to unknown error")
                }
            }
            
            if(notes.count > 0){
                print(notes.count)
                self.notes = notes
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
  
            }
            return nil
        }
        
    }
    

}
