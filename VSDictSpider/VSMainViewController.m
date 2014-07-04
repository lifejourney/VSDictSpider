//
//  VSMainViewController.m
//  VSDictSpider
//
//  Created by steven.zhuang on 7/3/14.
//  Copyright (c) 2014 StevenZhuang. All rights reserved.
//

#import "VSMainViewController.h"
#import "NSString+Trim.h"
#import "NSString+SubString.h"
#import "TFHpple.h"


@interface VSMainViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) IBOutlet NSTextField *siteTextField;
@property (nonatomic, strong) IBOutlet NSTextField *wordTextField;

- (IBAction) forIciba: (id)sender;

@property (nonatomic, strong) NSString *currentSite;
@property (nonatomic, strong) NSString *currentWord;
@property (nonatomic, strong) NSURLConnection *httpConnection;
@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, strong) NSError *connectionError;

- (void) checkAndCreateCurrentDictFolder;

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
        self.currentSite = self.siteTextField.stringValue;
        self.currentWord = self.wordTextField.stringValue;
        
        [self checkAndCreateCurrentDictFolder];
        
        NSString *urlString = [NSString stringWithFormat: @"http://%@/%@", _currentSite, _currentWord];
        NSString *httpMethod = @"GET";
        NSDictionary *headers = @{@"User-Agent": @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.76.4 (KHTML, like Gecko) Version/7.0.4 Safari/537.76.4"};
        
        
        
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

#define kVSDictKey_wordName @"00 wordName"
#define kVSDictKey_ttsFile @"ttsFile"
#define kVSDictKey_siteURL @"siteURL"
#define kVSDictKey_exam @"exam" //CET4, 6
#define kVSDictKey_category @"category" //N, V, ADJ
#define kVSDictKey_frequency @"frequency"
#define kVSDictKey_phonetics @"phonetics"
#define kVSDictKey_synonyms @"synonyms"
#define kVSDictKey_antonyms @"antonyms"
#define kVSDictKey_idiomAndPhrases @"phrases"
#define kVSDictKey_wordRoots @"wordRoots"
#define kVSDictKey_wordRoot @"wordRoot"
#define kVSDictKey_explain @"explain"
#define kVSDictKey_text @"text"
#define kVSDictKey_relatedWords @"relatedWords"
#define kVSDictKey_Collins @"Collins"
#define kVSDictKey_explain_CN @"CN"
#define kVSDictKey_explain_EN @"EN"
#define kVSDictKey_samples @"samples"
#define kVSDictKey_sentence @"sentence"

- (NSString*)dictFolder: (NSString*)site
{
    NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
    
    return [NSString stringWithFormat: @"%@/%@", desktopPath, site];
}

- (NSString*)dictFile: (NSString*)site word: (NSString*)word
{
    return [NSString stringWithFormat: @"%@/%@", [self dictFolder: site], word];
}

- (NSString*)failListFile: (NSString*)site
{
    return [NSString stringWithFormat: @"%@/%@", [self dictFolder: site], @"__failList"];
}

- (void) saveToFailList: (NSString*)site word: (NSString*)word  errorDescripton: (NSString*)errorDescripton
{
    NSString *fileName = [self failListFile: site];
    NSMutableDictionary *failList = [[NSMutableDictionary alloc] initWithContentsOfFile: fileName];
    
    [failList setValue: errorDescripton forKeyPath: word];
    
    [failList writeToFile: fileName atomically: YES];
}

- (void) saveToFailList: (NSString*)errorDescripton
{
    [self saveToFailList: _currentSite word: _currentWord errorDescripton: errorDescripton];
}

- (NSString*) parser: (TFHpple*)htmlParser textOfFirstElementWithPath: (NSString*)xPathOrCSS
{
    TFHppleElement *element = [htmlParser peekAtSearchWithXPathQuery: xPathOrCSS];
    
    return [element text];
}

- (NSString*) parentElement: (TFHppleElement*)parentElement textOfFirstElementWithPath: (NSString*)xPathOrCSS
{
    TFHppleElement *element = [parentElement peekAtSearchWithXPathQuery: xPathOrCSS];
    
    return [element text];
}

- (void) checkAndCreateCurrentDictFolder
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dictFolder = [self dictFolder: _currentSite];
    
    if (![fileManager fileExistsAtPath: dictFolder])
    {
        NSError *error;
        
        if (![fileManager createDirectoryAtPath: dictFolder withIntermediateDirectories: YES attributes: nil error: &error])
        {
            NSLog(@"Create Directory [%@] fail [%ld]: %@", dictFolder, [error code], [error description]);
        }
    }
}

- (void) parseHTML: (TFHpple*)htmlParser toDict: (NSMutableDictionary*)dict
{
    NSArray *eleArray;
    TFHppleElement *element;
    TFHppleElement *node;
    NSString *text;
    
    //NSString *frequency = [self parser: htmlParser textOfFirstElementWithPath: @"//div[@id='frequence_ec_word']/div[@class='tips_content']"];
    
    //////////////////////////////
    element = [htmlParser peekAtSearchWithXPathQuery: @"//ul[@class='star']/li[@class='star_current']/@style"];
    text = [element text];
    NSInteger width = [text subStringAfter: @"width:" before: @"px"].integerValue;
    NSNumber *frequency = [NSNumber numberWithInteger: width / 14];
    [dict setValue: frequency forKey: kVSDictKey_frequency];
    
    //////////////////////////////
    NSMutableArray *examArray = [[NSMutableArray alloc] init];
    eleArray = [htmlParser searchWithXPathQuery: @"//div[@class='wd_genre']/a"];
    for (element in eleArray)
    {
        text = [element text];
        [examArray addObject: [text trimAllSpace]];
    }
    [dict setValue: examArray forKeyPath: kVSDictKey_exam];
    
    //////////////////////////////
    NSMutableArray *phoneticArray = [[NSMutableArray alloc] init];
    eleArray = [htmlParser searchWithXPathQuery: @"//div[@class='prons']/span[@class='eg']"];
    for (element in eleArray)
    {
        NSString *category = [self parentElement: element textOfFirstElementWithPath: @"//span[@class='fl']"];
        NSString *phonetic = [self parentElement: element textOfFirstElementWithPath: @"//span[@class='fl']/strong[2]"];
        NSString *siteURL = [self parentElement: element textOfFirstElementWithPath: @"//div[@class='vCri']/a/@onclick"];
        siteURL = [siteURL subStringAfter: @"('" before: @"')"];
        
        NSDictionary *phoneticDict = @{kVSDictKey_category: [category trimAllControl],
                                       kVSDictKey_text: phonetic,
                                       kVSDictKey_siteURL: siteURL,
                                       kVSDictKey_ttsFile: @""};
        
        [phoneticArray addObject: phoneticDict];
    }
    
    [dict setValue: phoneticArray forKeyPath: kVSDictKey_phonetics];
    //////////////////////////////
    
    //////////////////////////////
    
    //////////////////////////////
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
    if (self.httpResponse)
    {
        NSInteger httpStatus = self.httpResponse.statusCode;
        BOOL isSuccess = (httpStatus >= 200 && httpStatus <= 299);
        
        if (isSuccess)
        {
            NSString *respString = [[NSString alloc] initWithData: self.receivedData encoding: NSUTF8StringEncoding];
            
            NSLog(@"Received response\n\n\n\n\n%@", respString);
            
            TFHpple *htmlParser = [[TFHpple alloc] initWithHTMLData: self.receivedData];
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setValue: _currentWord forKey: kVSDictKey_wordName];
            
            [self parseHTML: htmlParser toDict: dict];
            
            NSError *error;
            NSString *fileName = [self dictFile: _currentSite word: _currentWord];
            NSData *data = [NSJSONSerialization dataWithJSONObject: dict options: 0 error: &error];
            if (data)
            {
                if (![data writeToFile: fileName options: NSDataWritingAtomic error: &error])
                {
                    NSLog(@"Failed to writeToFile: %@", fileName);
                    
                    [self saveToFailList: [NSString stringWithFormat: @"Save to file fail [%ld]: %@", error.code, error.description]];
                }
            }
            else
            {
                [self saveToFailList: [NSString stringWithFormat: @"Convert to JSON fail [%ld]: %@", error.code, error.description]];
            }
        }
        else
        {
            [self saveToFailList: [NSString stringWithFormat: @"HTTP Status: %ld", httpStatus]];
        }
    }
    else
    {
        [self saveToFailList: @"Invalid response."];
    }
}

- (void) connection: (NSURLConnection *)connection didFailWithError: (NSError *)error
{
    NSString *errorDescription = [NSString stringWithFormat: @"Connection error[%ld] reason: %@.", [error code], [error localizedFailureReason]];
    NSLog(@"%@ \n response: %@", errorDescription, self.httpResponse);
    self.connectionError = error;
    
    self.httpConnection = nil;
    
    [self saveToFailList: errorDescription];
}

@end
