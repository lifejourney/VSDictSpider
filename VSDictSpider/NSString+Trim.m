//
//  NSString+Trim.m
//  VSDictSpider
//
//  Created by steven.zhuang on 7/4/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import "NSString+Trim.h"

@implementation NSString (Trim)

- (NSString*) trimSpaceAndReturn
{
    return [self stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end









