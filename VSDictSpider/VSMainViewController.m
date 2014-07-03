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

@property (nonatomic, strong) IBOutlet NSTextField *siteTextField;
@property (nonatomic, strong) IBOutlet NSTextField *wordTextField;

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
        NSString *urlString = [NSString stringWithFormat: @"http://%@/%@", self.siteTextField.stringValue, self.wordTextField.stringValue];
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

- (NSString*) parser: (TFHpple*)htmlParser textOfFirstElementWithPath: (NSString*)xPathOrCSS
{
    TFHppleElement *element = [htmlParser peekAtSearchWithXPathQuery: xPathOrCSS];
    
    return [element text];
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

#define kVSDictKey_wordName @"wordName"
#define kVSDictKey_ttsFile @"ttsFile"
#define kVSDictKey_siteURL @"siteURL"
#define kVSDictKey_category @"category"
#define kVSDictKey_frequency @"frequency"
#define kVSDictKey_phonetics @"phonetics"
#define kVSDictKey_synonyms @"synonyms"
#define kVSDictKey_antonyms @"antonyms"
#define kVSDictKey_idiomAndPhrases @"phrases"
#define kVSDictKey_wordRoots @"wordRoots"
#define kVSDictKey_wordRoot @"wordRoot"
#define kVSDictKey_explain @"explain"
#define kVSDictKey_relatedWords @"relatedWords"
#define kVSDictKey_Collins @"Collins"
#define kVSDictKey_explain_CN @"CN"
#define kVSDictKey_explain_EN @"EN"
#define kVSDictKey_samples @"samples"
#define kVSDictKey_sentence @"sentence"


- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    if (self.httpResponse)
    {
        NSString *respString = [[NSString alloc] initWithData: self.receivedData encoding: NSUTF8StringEncoding];
        
        NSLog(@"Received response\n\n\n\n\n%@", respString);
        
        
        TFHpple *htmlParser = [[TFHpple alloc] initWithHTMLData: self.receivedData];
        TFHppleElement *element;
        
        NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
        NSString *siteName = self.siteTextField.stringValue;
        NSString *wordName = self.wordTextField.stringValue;
        NSString *fileName = [NSString stringWithFormat: @"%@/%@/%@", desktopPath, siteName, wordName];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        NSString *frequency = [self parser: htmlParser textOfFirstElementWithPath: @"//div[@id='frequence_ec_word']/div[@class='tips_content']"];
        
        [dict setValue: wordName forKey: kVSDictKey_wordName];
        [dict setValue: frequency forKey: kVSDictKey_frequency];
        
        if (![dict writeToFile: fileName atomically: YES])
        {
            NSLog(@"Failed to writeToFile: %@", fileName);
        }
    }
}

- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
    NSLog(@"Connection error[%ld] reason: %@. \n response: %@", (long)[error code], [error localizedFailureReason], self.httpResponse);
    self.connectionError = error;
    
    self.httpConnection = nil;
}

@end
