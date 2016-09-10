//
//  RandomData.m
//  Comic Phreak DB
//
//  Created by Mudit Vats on 1/26/14.
//  Copyright (c) 2014 HealthPro Solutions, LLC. All rights reserved.
//

#import "RandomData.h"
#import "DbManager.h"

@implementation RandomData

NSString * const groupsArray[] = { @"Batman", @"Wonder Woman", @"Superman", @"Green Lantern", @"Supergirl", @"Wonder Twins", @"Aquaman", @"2000 AD", @"Cat Woman", @"Hawkgirl", @"Demon Batman", @"Firestar", @"Kikkoman"};

+ (void) GenerateRandomDataWithQuantity: (int) quantity
{
	for (int i=0; i<quantity; i++)
	{
		[RandomData GenerateRandomData];
	}
}

+ (void) GenerateRandomData
{
	DbManager *dbManager = [DbManager sharedInstance];
	
	[dbManager insertRecordWithName: [RandomData GetRandomFilename]
					   AndGroupName: [RandomData GetRandomGroup]
						AndFileSize: [RandomData GetRandomFileSize]
					 AndDateCreated: Nil
					AndDateModified: Nil
					AndDateAccessed: Nil
					  AndTotalPages: 0
					 AndCurrentPage: 0
			   AndThumbNailFileName: Nil
						AndIsUnread: 0
					   AndIsDeleted: 0
						 AndIsValid: [RandomData GetRandomIsValid]];
	

}

+ (NSString *) GetRandomFilename
{
	NSString *letters = @"abcdefghijklmnopqrstuvwxyz ABCDEFGHJIKLMNOPQRSTUVWXYZ 0123456789   ";

	NSMutableString *filename = [NSMutableString stringWithCapacity:50];
	
	int maxNameLength = MAX(20,  arc4random_uniform(40));
	
	for (int i=0; i<maxNameLength; i++)
	{
		NSInteger index = arc4random_uniform([letters length]);
		NSString *randomLetter = [letters substringWithRange:NSMakeRange(index, 1)];
		
		[filename appendString:randomLetter];
	}
	
	[filename appendString:@".cbz"];
	
	return  filename;
}

+ (NSString *) GetRandomGroup
{
	int groupNumber = arc4random_uniform(13);
	return groupsArray[groupNumber];
}


+ (int) GetRandomFileSize
{
	int randomSize = abs(arc4random());
	return randomSize;
}

+ (int) GetRandomIsValid
{
    int randomIsValid = arc4random_uniform(2);
    
    return randomIsValid;
}

@end
