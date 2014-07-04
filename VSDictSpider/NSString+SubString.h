//
//  NSString+SubString.h
//  VSDictSpider
//
//  Created by steven.zhuang on 7/4/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SubString)

- (NSString*) subStringAfter: (NSString*)prefix before: (NSString*)subfix;

@end
