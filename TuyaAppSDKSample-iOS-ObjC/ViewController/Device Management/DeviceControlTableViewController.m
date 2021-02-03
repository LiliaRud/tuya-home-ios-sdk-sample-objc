//
//  DeviceControlTableViewController.m
//  TuyaAppSDKSample-iOS-ObjC
//
//  Copyright (c) 2014-2021 Tuya Inc. (https://developer.tuya.com/)

#import "DeviceControlTableViewController.h"
#import "SVProgressHUD.h"
#import "DeviceControlCellHelper.h"
#import "NotificationName.h"
#import "SwitchTableViewCell.h"
#import "SliderTableViewCell.h"
#import "EnumTableViewCell.h"
#import "StringTableViewCell.h"
#import "LabelTableViewCell.h"
#import "NotificationName.h"

@interface DeviceControlTableViewController () <TuyaSmartDeviceDelegate>

@end

@implementation DeviceControlTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.title = self.device.deviceModel.name;
    self.device.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceHasRemoved:) name:SVProgressHUDDidDisappearNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self detectDeviceAvailability];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [SVProgressHUD dismiss];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceHasRemoved:) name:SVProgressHUDDidDisappearNotification object:nil];
}

- (void)publishMessage:(NSDictionary *) dps {
    [self.device publishDps:dps success:^{
            
    } failure:^(NSError *error) {
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

- (void)detectDeviceAvailability {
    bool isOnline = self.device.deviceModel.isOnline;
    if (!isOnline) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceOffline object:nil];
        [SVProgressHUD showWithStatus:NSLocalizedString(@"The device is offline. The control panel is unavailable.", @"")];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceOnline object:nil];
        [SVProgressHUD dismiss];
    }
}

- (void)deviceHasRemoved:(NSNotification *)notification {
    NSString *key = notification.userInfo[SVProgressHUDStatusUserInfoKey];
    if ([key containsString:@"removed"]) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.device) {
        return 0;
    } else {
        return self.device.deviceModel.schemaArray.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    TuyaSmartDevice *device = self.device;
    TuyaSmartSchemaModel *schema = device.deviceModel.schemaArray[indexPath.row];
    NSDictionary *dps = device.deviceModel.dps;
    NSString *cellIdentifier = [DeviceControlCellHelper cellIdentifierWithSchemaModel:schema];
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (([DeviceControlCellHelper cellTypeWithSchemaModel:schema]) == switchCell) {
        ((SwitchTableViewCell *)cell).label.text = schema.name;
        [((SwitchTableViewCell *)cell).switchButton setOn:[dps[schema.dpId] boolValue]];
        ((SwitchTableViewCell *)cell).switchAction = ^(UISwitch *switchButton) {
            [self publishMessage:@{schema.dpId: [NSNumber numberWithBool:switchButton.isOn]}];
        };
    } else if (([DeviceControlCellHelper cellTypeWithSchemaModel:schema]) == sliderCell) {
        ((SliderTableViewCell *)cell).label.text = schema.name;
        ((SliderTableViewCell *)cell).detailLabel.text = [dps[schema.dpId] stringValue];
        ((SliderTableViewCell *)cell).slider.minimumValue = schema.property.min;
        ((SliderTableViewCell *)cell).slider.maximumValue = schema.property.max;
        [((SliderTableViewCell *)cell).slider setContinuous:NO];
        ((SliderTableViewCell *)cell).slider.value = [dps[schema.dpId] floatValue];
        ((SliderTableViewCell *)cell).sliderAction = ^(UISlider * _Nonnull slider) {
            float step = schema.property.step;
            float roundedValue = round(slider.value / step) * step;
            [self publishMessage:@{schema.dpId : @((int)roundedValue)}];
        };
    } else if (([DeviceControlCellHelper cellTypeWithSchemaModel:schema]) == enumCell) {
        ((EnumTableViewCell *)cell).label.text = schema.name;
        ((EnumTableViewCell *)cell).optionArray = [schema.property.range mutableCopy];
        ((EnumTableViewCell *)cell).currentOption = dps[schema.dpId];
        ((EnumTableViewCell *)cell).selectAction = ^(NSString * _Nonnull option) {
            [self publishMessage:@{schema.dpId: dps[schema.dpId]}];
        };
    } else if (([DeviceControlCellHelper cellTypeWithSchemaModel:schema]) == stringCell) {
        ((StringTableViewCell *)cell).label.text = schema.name;
        ((StringTableViewCell *)cell).textField.text = dps[schema.dpId];
        ((StringTableViewCell *)cell).buttonAction = ^(NSString * _Nonnull text) {
            [self publishMessage:@{schema.dpId: dps[schema.dpId]}];
        };
    } else if (([DeviceControlCellHelper cellTypeWithSchemaModel:schema]) == labelCell) {
        ((LabelTableViewCell *)cell).label.text = schema.name;
        ((LabelTableViewCell *)cell).detailLabel.text = dps[schema.dpId];
    }
    
    return cell;
}

-(void)deviceInfoUpdate:(TuyaSmartDevice *)device {
    [self detectDeviceAvailability];
    [self.tableView reloadData];
}

-(void)deviceRemoved:(TuyaSmartDevice *)device {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceOffline object:nil];
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"The device has been removed.", @"")];
}

-(void)device:(TuyaSmartDevice *)device dpsUpdate:(NSDictionary *)dps {
    [self detectDeviceAvailability];
    [self.tableView reloadData];
}
@end
