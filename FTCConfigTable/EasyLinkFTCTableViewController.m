//
//  EasyLinkFTCTableViewController.m
//  EasyLink
//
//  Created by William Xu on 14-3-24.
//  Copyright (c) 2014年 MXCHIP Co;Ltd. All rights reserved.
//

#import "EasyLinkFTCTableViewController.h"
#import "FTCStringCell.h"
#import "FTCStringSelectCell.h"
#import "FTCSwitchCell.h"
#import "FTCSubMenuCell.h"
#import "CustomIOS7AlertView.h"
#import "EasyLinkOTATableViewController.h"

@interface EasyLinkFTCTableViewController ()

@end

@implementation EasyLinkFTCTableViewController
@synthesize configData = _configData;
@synthesize otaPath;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)delegate
{
	return theDelegate;
}

- (void)setDelegate:(id)delegate
{
    theDelegate = delegate;
}

- (void)dealloc{
    theDelegate = nil;
    NSLog(@"FTC tableview dealloced!");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    /*Return from a select cell, update the select cell and add the new valuw to the config data*/
    if(selectCellIndexPath != nil){

        NSArray *array =[[self.configMenu objectAtIndex:[ selectCellIndexPath indexAtPosition: 0 ]-hasOTA] objectForKey:@"C"];
        NSMutableDictionary *content = [array objectAtIndex: [ selectCellIndexPath indexAtPosition: 1 ]];
        
        FTCStringSelectCell *cell = (FTCStringSelectCell *)[configTableView cellForRowAtIndexPath:selectCellIndexPath];
        if([[content objectForKey:@"C"] isKindOfClass:[NSNumber class]])
            cell.contentText.text = [[content objectForKey:@"C"] stringValue];
        else
            cell.contentText.text = [content objectForKey:@"C"];

        NSLog(@"Select cell changed");
        
        [self editingChanged: cell.contentText.text AtIndexPath:[NSIndexPath indexPathForRow:cell.contentRow inSection:cell.sectionRow]];
        selectCellIndexPath = nil;
    }
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setConfigData:(NSMutableDictionary *)newConfigData
{
    NSString *protocol;
    NSString *hardwareVersion;
    
    if (_configData != newConfigData) {
        _configData = newConfigData;
        
        // Update the view.
        self.configMenu = [newConfigData objectForKey:@"C"];
        protocol = [newConfigData objectForKey:@"PO"];
        hardwareVersion = [newConfigData objectForKey:@"HD"];
        
        currentVersion = [newConfigData objectForKey:@"FW"];
        if( protocol!=nil&&hardwareVersion!=nil) {
            hasOTA = true;
        }
        else
            hasOTA = false;
        [configTableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.configMenu count]+hasOTA;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(section == 0&&hasOTA)
        return 1;
    else
        return [[[self.configMenu objectAtIndex:(section-hasOTA)] objectForKey:@"C"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0&&hasOTA)
        return @"";
    else
        return [[self.configMenu objectAtIndex:(section-hasOTA)] objectForKey:@"N"];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    FTCStringCell *ftcStringcell;
    FTCSwitchCell *ftcSwitchcell;
    FTCStringSelectCell *ftcStringSelectCell;
    FTCSubMenuCell *ftcSubMenuCell;
    
    NSString *tableCellIdentifier;
    
    /*Display OTA cell*/
    if([ indexPath indexAtPosition: 0 ] == 0&&hasOTA){
        tableCellIdentifier= @"OTACell";
        cell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
        cell.detailTextLabel.text = currentVersion;
        cell.detailTextLabel.textColor = [UIColor whiteColor];
        return cell;
    }
    
    NSUInteger sectionRow = [ indexPath indexAtPosition: 0 ]-hasOTA;
    NSUInteger contentRow = [ indexPath indexAtPosition: 1 ];
    NSArray *array =[[self.configMenu objectAtIndex:sectionRow] objectForKey:@"C"];
    NSMutableDictionary *content = [array objectAtIndex: contentRow];
    
    if([[content objectForKey:@"C"] isKindOfClass:[NSArray class]]){             //Sub menu
        tableCellIdentifier = @"SubMenuCell";
        ftcSubMenuCell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
        ftcSubMenuCell.textLabel.text = [content objectForKey:@"N"];
        return ftcSubMenuCell;
    }else if([[content objectForKey:@"C"] isKindOfClass:[NSNumber class]]){     //Number cell
        const char * pObjCType = [(NSNumber *)[content objectForKey:@"C"] objCType];
        if(strcmp(pObjCType, @encode(char))==0){ //Same as Bool type
            tableCellIdentifier = @"SwitchCell";
            ftcSwitchcell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
            ftcSwitchcell.ftcConfig  = content;
            ftcSwitchcell.sectionRow = sectionRow;
            ftcSwitchcell.contentRow = contentRow;
            [ftcSwitchcell setDelegate:self];
            return ftcSwitchcell;
        }
        else{
            if([content objectForKey:@"S"]==nil){
                tableCellIdentifier= @"ConfigCell";
                ftcStringcell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
                ftcStringcell.ftcConfig  = content;
                ftcStringcell.sectionRow = sectionRow;
                ftcStringcell.contentRow = contentRow;
                [ftcStringcell setDelegate:self];
                return ftcStringcell;
            }
            else{
                tableCellIdentifier= @"SelectCell";
                ftcStringSelectCell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
                ftcStringSelectCell.ftcConfig  = content;
                ftcStringSelectCell.sectionRow = sectionRow;
                ftcStringSelectCell.contentRow = contentRow;
                [ftcStringSelectCell setDelegate:self];
                return ftcStringSelectCell;
            }
        }
    }else{                                                                      //String cell
        if([content objectForKey:@"S"]==nil){
            tableCellIdentifier= @"ConfigCell";
            ftcStringcell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
            ftcStringcell.ftcConfig  = content;
            ftcStringcell.sectionRow = sectionRow;
            ftcStringcell.contentRow = contentRow;
            [ftcStringcell setDelegate:self];
            return ftcStringcell;
        }
        else{
            tableCellIdentifier= @"SelectCell";
            ftcStringSelectCell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
            ftcStringSelectCell.ftcConfig  = content;
            ftcStringSelectCell.sectionRow = sectionRow;
            ftcStringSelectCell.contentRow = contentRow;
            [ftcStringSelectCell setDelegate:self];
            return ftcStringSelectCell;
        }
    }
    return nil;
}

#pragma mark - "Confirm" Button action
- (IBAction)applyNewConfigData
{
    if([theDelegate respondsToSelector:@selector(onConfigured:)])
        [theDelegate onConfigured:self.configData];
}

#pragma mark - Segue action

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"Sub menu"]) {
        NSIndexPath *indexPath = [configTableView indexPathForSelectedRow];
        NSUInteger sectionRow = [ indexPath indexAtPosition: 0 ]-hasOTA;
        NSUInteger contentRow = [ indexPath indexAtPosition: 1 ];
        NSArray *array =[[self.configMenu objectAtIndex:sectionRow] objectForKey:@"C"];
        NSMutableDictionary *content = [array objectAtIndex: contentRow];
        
        [configTableView deselectRowAtIndexPath:indexPath animated:YES];
        /*Add client and update content in sub menu*/
        [content setObject:[self.configData objectForKey:@"client"] forKey:@"client"];
        [content setObject:[self.configData objectForKey:@"update"] forKey:@"update"];
        [[segue destinationViewController] setConfigData: content];
        [[[segue destinationViewController] navigationItem] setTitle: [content objectForKey:@"N"]];
        [[segue destinationViewController] setDelegate:theDelegate];
    }
    
    if ([[segue identifier] isEqualToString:@"Select Table"]) {
        selectCellIndexPath = [configTableView indexPathForSelectedRow];
        NSUInteger sectionRow = [ selectCellIndexPath indexAtPosition: 0 ]-hasOTA;
        NSUInteger contentRow = [ selectCellIndexPath indexAtPosition: 1 ];
        NSArray *array =[[self.configMenu objectAtIndex:sectionRow] objectForKey:@"C"];
        NSMutableDictionary *content = [array objectAtIndex: contentRow];
        
        [configTableView deselectRowAtIndexPath:selectCellIndexPath animated:YES];
        [[segue destinationViewController] setConfigData: content];
        [[[segue destinationViewController] navigationItem] setTitle:[content objectForKey:@"N"]];
    }
    
    if ([[segue identifier] isEqualToString:@"OTA"]) {
        [[segue destinationViewController] setProtocol:[self.configData objectForKey:@"PO"]];
        [[segue destinationViewController] setClient:[self.configData objectForKey:@"client"]];
        [[segue destinationViewController] setHardwareVersion: [self.configData objectForKey:@"HD"]];
        [[segue destinationViewController] setFirmwareVersion: [self.configData objectForKey:@"FW"]];
        [[segue destinationViewController] setRfVersion: [self.configData objectForKey:@"RF"]];
        [[segue destinationViewController] setDelegate:theDelegate];
    }
}

#pragma mark - Switch button action on the cell

- (void) switchChanged: (NSNumber *)onoff AtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Value changed!");
    NSUInteger sectionRow = [ indexPath indexAtPosition: 0 ];
    NSUInteger contentRow = [ indexPath indexAtPosition: 1 ];
    NSArray *array =[[self.configMenu objectAtIndex:sectionRow] objectForKey:@"C"];
    NSMutableDictionary *content = [array objectAtIndex: contentRow];
    NSMutableDictionary *updateSetting = [self.configData objectForKey:@"update"];
    [updateSetting setObject:(onoff.boolValue == YES)? @YES:@NO forKey:[content objectForKey:@"N"]];
}



#pragma mark - textField content changed on the cell

- (void)editingChanged: (NSString *)textString AtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Value changed!");
    NSUInteger sectionRow = [ indexPath indexAtPosition: 0 ];
    NSUInteger contentRow = [ indexPath indexAtPosition: 1 ];
    NSArray *array =[[self.configMenu objectAtIndex:sectionRow] objectForKey:@"C"];
    NSMutableDictionary *content = [array objectAtIndex: contentRow];
    NSMutableDictionary *updateSetting = [self.configData objectForKey:@"update"];
    if([[content objectForKey:@"C"] isKindOfClass:[NSString class]])
        [updateSetting setObject:textString forKey:[content objectForKey:@"N"]];
    else {
        const char *pObjCType = [(NSNumber *)[content objectForKey:@"C"] objCType];
        if( strcmp(pObjCType, @encode(int)) == 0 )
            [updateSetting setObject: [NSNumber numberWithInt:[textString intValue]] forKey:[content objectForKey:@"N"]];
        else if( strcmp(pObjCType, @encode(long long)) == 0 )
            [updateSetting setObject: [NSNumber numberWithLongLong:[textString longLongValue]] forKey:[content objectForKey:@"N"]];
        else if( strcmp(pObjCType, @encode(NSInteger)) == 0 )
            [updateSetting setObject: [NSNumber numberWithInteger:[textString integerValue]] forKey:[content objectForKey:@"N"]];
        else if( strcmp(pObjCType, @encode(float)) == 0)
            [updateSetting setObject: [NSNumber numberWithFloat:[textString floatValue]] forKey:[content objectForKey:@"N"]];
        else if( strcmp(pObjCType, @encode(double)) == 0 )
            [updateSetting setObject: [NSNumber numberWithDouble:[textString doubleValue]] forKey:[content objectForKey:@"N"]];
    }
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
