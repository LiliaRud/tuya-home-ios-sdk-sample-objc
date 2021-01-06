//
//  MainTableViewController.m
//  TuyaAppSDKSample-iOS-ObjC
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

#import "MainTableViewController.h"
#import "Alert.h"

@interface MainTableViewController ()

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

#pragma mark - IBAction

- (IBAction)logout:(UIButton *)sender {
    [[TuyaSmartUser sharedInstance] loginOut:^{
        [Alert showBasicAlertOnVC:self withTitle:@"Successfully Logged Out" message:@"Most of the functions will be unusable."];

    } failure:^(NSError *error) {
        [Alert showBasicAlertOnVC:self withTitle:@"Failed to Logout." message:error.localizedDescription];
    }];
}


#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
