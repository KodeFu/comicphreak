//
//  LibraryTableViewCellController.h
//  ComicPhreak
//
//  Created by Mudit Vats on 10/12/16.
//  Copyright © 2016 HealthPro Solutions, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LibraryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *thumbnailButton;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) NSString *fileName;

- (void) updateProperties;

@end
