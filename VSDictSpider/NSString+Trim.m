//
//  NSString+Trim.m
//  VSDictSpider
//
//  Created by steven.zhuang on 7/4/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import "NSString+Trim.h"

@implementation NSString (Trim)

- (NSString*) removeSubString: (NSString*)substring
{
    return [self stringByReplacingOccurrencesOfString: substring withString: @""];
}

- (NSString*) trimAllSpace
{
    NSString *ret = [self removeSubString: @" "];
    ret = [ret removeSubString: @" "];
    
    return ret;
}

- (NSString*) trimReturn
{
    NSString *ret = [self removeSubString: @"\r"];
    ret = [ret removeSubString: @"\n"];
    
    return ret;
}

- (NSString*) trimTab
{
    NSString *ret = [self removeSubString: @"\t"];
    
    return ret;
}

- (NSString*) trimAllControl
{
    NSString *ret = [self trimAllSpace];
    ret = [ret trimTab];
    ret = [ret trimReturn];
    
    return ret;
}

@end
