//
//  NSString+SubString.h
//  VSDictSpider
//
//  Created by steven.zhuang on 7/4/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SubString)

- (NSString*) removeAllSpace;
- (NSString*) removeReturn;
- (NSString*) removeTab;
- (NSString*) removeAllControl;

- (NSString*) subStringAfter: (NSString*)prefix before: (NSString*)subfix;
- (NSString*) substringByRemovePrefix: (NSString*)prefix;

@end
