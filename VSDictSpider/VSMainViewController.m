//
//  VSMainViewController.m
//  VSDictSpider
//
//  Created by steven.zhuang on 7/3/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import "VSMainViewController.h"
#import "TFHpple.h"


@interface VSMainViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (IBAction) forIciba: (id)sender;

@property (nonatomic, strong) NSURLConnection *httpConnection;
@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSError *connectionError;

@end

@implementation VSMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (IBAction) forIciba: (id)sender
{
    NSError *error;
    self.httpResponse = nil;
    self.connectionError = nil;
    self.receivedData = [[NSMutableData alloc] init];
    
    NSDictionary *bodyDict = @{};
    
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject: bodyDict
                                                       options: 0
                                                         error: &error];
    if (bodyData)
    {
        NSString *urlString = @"http://www.iciba.com/incoming";
        NSString *httpMethod = @"GET";
        NSDictionary *headers = @{};
        
        
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: urlString]
                                                               cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                           timeoutInterval: 30];
        [request setHTTPMethod: httpMethod];
        [request setAllHTTPHeaderFields: headers];
        //[request setHTTPBody: bodyData];
        [request setHTTPShouldHandleCookies: NO];
        
        self.httpConnection = [[NSURLConnection alloc] initWithRequest: request
                                                              delegate: self
                                                      startImmediately: YES];
    }
}


- (NSURLRequest*) connection: (NSURLConnection *)connection
             willSendRequest: (NSURLRequest *)request
            redirectResponse: (NSURLResponse *)response
{
    return request;
}

- (void) connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)response
{
    self.httpResponse = (NSHTTPURLResponse *)response;
}

- (void) connection: (NSURLConnection *)connection didReceiveData: (NSData *)data
{
    [self.receivedData appendData: data];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    NSError *error;
    
    if (self.httpResponse)
    {
        NSString *respString = [[NSString alloc] initWithData: self.receivedData encoding: NSUTF8StringEncoding];
        
        NSLog(@"Received response\n\n\n\n\n%@", respString);
        
        
        TFHpple *htmlParser = [[TFHpple alloc] initWithHTMLData: self.receivedData];
        NSArray *elements = [htmlParser searchWithXPathQuery: @"//div[@id='frequence_ec_word']/div[@class='tips_content']"];
        for (TFHppleElement *ele in elements)
        {
            NSString *content = [ele raw];
            NSLog(@"%@", content);
        }
    }
}

- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
    NSLog(@"Connection error[%d] reason: %@. \n response: %@", [error code], [error localizedFailureReason], self.httpResponse);
    self.connectionError = error;
    
    self.httpConnection = nil;
}

@end
