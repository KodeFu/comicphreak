//
//  TableViewController.m
//  Comic Phreak DB
//
//  Created by Mudit Vats on 9/8/13.
//  Copyright (c) 2013 HealthPro Solutions, LLC. All rights reserved.
//

#import "LibraryTableViewController.h"
#import "ContentViewController.h"
#import "DbManager.h"
#import "Debug.h"
#import "TableViewCell.h"

#import "DirectoryManager.h"

@interface LibraryTableViewController ()
{
    NSArray *SuperMonsterList;
}

@end

@implementation LibraryTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];

    if (self)
	{
        // Custom initialization
		
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	// DEBUG
	[DirectoryManager sharedInstance];
    
    // Register for notification events
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receiveNotification:)
                                                 name:@"START_SYNC"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(receiveNotification:)
                                                 name:@"STOP_SYNC"
                                               object:nil];
    
    // Customize navigation color
    // PList: View controller-based status bar appearance = NO
    /*[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];*/
    
    // Maybe abstract this somewhere since this is a size thing?
    // Set the size of the table view inset else last row gets chopped by tabBar
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0f);
}

- (void) receiveNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"START_SYNC"])
	{
        DLOG(@"START_SYNC... tableview");
	}
	else if ([[notification name] isEqualToString:@"STOP_SYNC"])
	{
        DLOG(@"STOP_SYNC... reload table data");
        
        [self performSelectorOnMainThread: @selector(reloadAllTableData)
							   withObject:Nil
							waitUntilDone:YES];
	}
}

- (void) reloadAllTableData
{
    [self.tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	DbManager *dbManager = [DbManager sharedInstance];
	
	if (dbManager == Nil)
	{
		return 0;
	}
    
    // FIXME: Cached List - think about this more?
    SuperMonsterList = [[DbManager sharedInstance] getAllRecordsByFileNameAndSortByAlphaAscending];
    
    return [SuperMonsterList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Get record from cached database
    NSDictionary *record = [SuperMonsterList objectAtIndex:[indexPath row]];
    NSString *fileName = [record objectForKey:@"FileName"];
	
    // Configure the cell...    
    [[cell nameLabel] setText:fileName];
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		// Delete the row in the table
		DbManager *dbManager = [DbManager sharedInstance];
		NSDictionary *record = [dbManager getRecordByIndex:indexPath.row];
		[dbManager setFileNameInvalid:[record valueForKey:@"FileName"]];
		
		// Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ContentViewController"])
    {
        TableViewCell *cell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        ContentViewController *contentViewController = [segue destinationViewController];
        [contentViewController setComicFileName:[[cell nameLabel] text]];
    
        DLOG(@"cell row we're segueing to %d", [indexPath row]);

    }
}

#pragma mark - Search delegate


- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    DLOG(@"search text: %@", searchText);
    
}


@end
