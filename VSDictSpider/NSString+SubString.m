//
//  NSString+SubString.m
//  VSDictSpider
//
//  Created by steven.zhuang on 7/4/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import "NSString+SubString.h"

@implementation NSString (SubString)

- (NSString*) subStringAfter: (NSString*)prefix before: (NSString*)subfix
{
    NSRange fromRange = [self rangeOfString: prefix];
    NSRange endRange = [self rangeOfString: subfix];
    NSString *subString;
    
    if (fromRange.location != NSNotFound && fromRange.length > 0 &&
        endRange.location != NSNotFound && endRange.length &&
        endRange.location >= fromRange.location)
    {
        NSUInteger loc = fromRange.location + fromRange.length;
        NSUInteger len = endRange.location >= loc ? endRange.location - loc : 0;
        
        NSRange range = NSMakeRange(loc, len);
        
        subString = [self substringWithRange: range];
    }
    else
        subString = @"";
    
    return subString;
}

@end
