//
//  NSString+SubString.m
//  VSDictSpider
//
//  Created by steven.zhuang on 7/4/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import "NSString+SubString.h"

@implementation NSString (SubString)

- (NSString*) removeSubString: (NSString*)substring
{
    return [self stringByReplacingOccurrencesOfString: substring withString: @""];
}

- (NSString*) removeAllSpace
{
    NSString *ret = [self removeSubString: @" "];
    ret = [ret removeSubString: @" "];
    
    return ret;
}

- (NSString*) removeReturn
{
    NSString *ret = [self removeSubString: @"\r"];
    ret = [ret removeSubString: @"\n"];
    
    return ret;
}

- (NSString*) removeTab
{
    NSString *ret = [self removeSubString: @"\t"];
    
    return ret;
}

- (NSString*) removeAllControl
{
    NSString *ret = [self removeAllSpace];
    ret = [ret removeTab];
    ret = [ret removeReturn];
    
    return ret;
}

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

- (NSString*) substringByRemovePrefix: (NSString*)prefix
{
    NSString *subString;
    
    if (prefix && [prefix length] > 0 && [self hasPrefix: prefix])
    {
        NSUInteger loc = prefix.length;
        NSUInteger len = self.length > prefix.length ? self.length - prefix.length : 0;
        
        subString = [self substringWithRange: NSMakeRange(loc, len)];
    }
    else
        subString = self;
    
    return subString;
}

@end
