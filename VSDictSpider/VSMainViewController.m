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


#define kGoogleOnlineTTS_URL @"http://translate.google.cn/translate_tts?tl=en&q="

@interface VSMainViewController () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) IBOutlet NSTextField *siteTextField;
@property (nonatomic, strong) IBOutlet NSTextField *wordTextField;

- (IBAction) forIciba: (id)sender;
- (IBAction) getWordList: (id)sender;

@property (nonatomic, strong) NSString *currentSite;
@property (nonatomic, strong) NSString *currentWord;
@property (nonatomic, strong) NSMutableDictionary *collinsCategoryDict;

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
        
        NSString *replacedWord = [_currentWord stringByReplacingOccurrencesOfString: @" " withString: @"_"];
        NSString *urlString = [NSString stringWithFormat: @"http://%@/%@", _currentSite, replacedWord];
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
    
    _collinsCategoryDict = [[NSMutableDictionary alloc] initWithContentsOfFile: [self collinsCategoryFile: _currentSite]];
    if (!_collinsCategoryDict)
        _collinsCategoryDict = [[NSMutableDictionary alloc] init];
}

- (NSArray*) keyArrayFromTxt1: (NSString*)txt
{
    NSArray *lines = [txt componentsSeparatedByString: @"\n"];
    
    NSMutableArray *keyArray = [[NSMutableArray alloc] initWithCapacity: [lines count]/2];
    for (NSUInteger i = 0; i < [lines count]; i += 2)
    {
        [keyArray addObject: [lines objectAtIndex: i]];
    }
    
    return keyArray;
}

- (NSArray*) keyArrayFromTxt2: (NSString*)txt
{
    NSArray *lines = [txt componentsSeparatedByString: @"\n"];
    
    NSMutableArray *keyArray = [[NSMutableArray alloc] initWithCapacity: [lines count]/2];
    for (NSUInteger i = 0; i < [lines count]; i++)
    {
        NSString *oneLine = [lines objectAtIndex: i];
        NSArray *wordArray = [oneLine componentsSeparatedByString: @" "];
        NSString *key = nil;
        for (NSUInteger w = 0; w < [wordArray count]; w++)
        {
            key = [wordArray objectAtIndex: w];
            
            if (key && [key length] > 0)
                break;
        }
        
        if (key && [key length] > 0)
            [keyArray addObject: key];
        else
            NSLog(@"Not key found in txt: %@", txt);
    }
    
    return keyArray;
}

- (IBAction) txtFile: (NSString*)txtFile toKeyListFile: (NSString*)keyListFile selType: (NSInteger)selType
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource: txtFile ofType: @"txt"];
    NSString *txt = [NSString stringWithContentsOfFile: filePath encoding: NSUTF8StringEncoding error: nil];
    
    NSArray *keyArray;
    if (selType == 1)
        keyArray = [self keyArrayFromTxt1: txt];
    else
        keyArray = [self keyArrayFromTxt2: txt];
    
    NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
    NSString *keyFilePath = [NSString stringWithFormat: @"%@/VSDictSpider/VSDictSpider/%@.plist", desktopPath, keyListFile];
    
    [keyArray writeToFile: keyFilePath atomically: YES];
}

- (IBAction) getWordList: (id)sender
{
    [self txtFile: @"ky" toKeyListFile: @"KY_List" selType: 1];
    [self txtFile: @"gre" toKeyListFile: @"GRE_List" selType: 1];
    [self txtFile: @"cet4" toKeyListFile: @"CET4_List" selType: 2];
    [self txtFile: @"cet6" toKeyListFile: @"CET6_List" selType: 2];
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
    //TO-DO, json not plist
    return [NSString stringWithFormat: @"%@/%@.plist", [self dictFolder: site], word];
}

- (NSString*)failListFile: (NSString*)site
{
    return [NSString stringWithFormat: @"%@/%@", [self dictFolder: site], @"__failList.plist"];
}

- (NSString*)collinsCategoryFile: (NSString*)site
{
    return [NSString stringWithFormat: @"%@/%@", [self dictFolder: site], @"__collinsCategory.plist"];
}

- (void) saveToFailList: (NSString*)site word: (NSString*)word  errorDescripton: (NSString*)errorDescripton
{
    NSString *fileName = [self failListFile: site];
    NSMutableDictionary *failList = [[NSMutableDictionary alloc] initWithContentsOfFile: fileName];
    if (!failList)
        failList = [[NSMutableDictionary alloc] init];
    
    [failList setValue: errorDescripton forKeyPath: word];
    
    [failList writeToFile: fileName atomically: YES];
}

- (void) saveToFailList: (NSString*)errorDescripton
{
    [self saveToFailList: _currentSite word: _currentWord errorDescripton: errorDescripton];
}

- (void) deleteErrorDescription
{
    [self saveToFailList: _currentSite word: _currentWord errorDescripton: nil];
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
    NSString *text;
    BOOL categoryUpdated = NO;
    
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
        [examArray addObject: [text removeAllSpace]];
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
        
        if (!category)
            category = @"";
        
        if (phonetic)
        {
            NSDictionary *phoneticDict = @{kVSDictKey_category: [category removeAllControl],
                                           kVSDictKey_text: phonetic,
                                           //kVSDictKey_siteURL: siteURL,
                                           //kVSDictKey_ttsFile: @""
                                           };
            
            [phoneticArray addObject: phoneticDict];
        }
    }
    
    [dict setValue: phoneticArray forKeyPath: kVSDictKey_phonetics];
    //////////////////////////////
    NSMutableArray *phraseArray = [[NSMutableArray alloc] init];
    NSString *ddTemplate = @"//div[@class='dict_content word_group']/dl[@class='def_list']/dd[@class='%@']";
    NSString *ddTemplates = [NSString stringWithFormat: @"%@ | %@", ddTemplate, ddTemplate];
    NSString *ddXPath = [NSString stringWithFormat: ddTemplates, @"dd_show", @"dd_hide"];
    eleArray = [htmlParser searchWithXPathQuery: ddXPath];
    for (element in eleArray)
    {
        NSString *phraseText = [self parentElement: element textOfFirstElementWithPath: @"//h4[@class='cx_mean_switch']"];
        
        if (phraseText)
        {
            NSMutableArray *meanArray = [[NSMutableArray alloc] init];
            TFHppleElement *divElement = [element peekAtSearchWithXPathQuery: @"//div[@class='ct_example']"];
            NSArray *textElementArray = [divElement searchWithXPathQuery: @"//h5"];
            
            NSInteger currentIndex = 1;
            for (TFHppleElement *textElement in textElementArray)
            {
                NSString *indexPrefix = [NSString stringWithFormat: @"%ld. ", currentIndex];
                NSString *enXPath = [NSString stringWithFormat: @"//ul[%ld]/li[1]", currentIndex];
                NSString *cnXPath = [NSString stringWithFormat: @"//ul[%ld]/li[2]", currentIndex];
                
                NSString *explainText = [textElement text];
                NSString *explainEN = [self parentElement: divElement textOfFirstElementWithPath: enXPath];
                NSString *explainCN = [self parentElement: divElement textOfFirstElementWithPath: cnXPath];
                
                if (explainText)
                {
                    NSMutableDictionary *meanDict = [[NSMutableDictionary alloc] initWithCapacity: 3];
                    [meanDict setValue: [explainText substringByRemovePrefix: indexPrefix] forKey: kVSDictKey_explain];
                    [meanDict setValue: [explainEN substringByRemovePrefix: indexPrefix] forKey: kVSDictKey_explain_EN];
                    [meanDict setValue: [explainCN substringByRemovePrefix: indexPrefix] forKey: kVSDictKey_explain_CN];
                    
                    [meanArray addObject:meanDict];
                }
                
                currentIndex++;
            }
            
            NSDictionary *phraseDict = @{kVSDictKey_text: phraseText,
                                         kVSDictKey_explain: meanArray};
            
            [phraseArray addObject: phraseDict];
        }
    }
    
    [dict setValue: phraseArray forKeyPath: kVSDictKey_idiomAndPhrases];
    //////////////////////////////
    NSMutableArray *synonymsArray = [[NSMutableArray alloc] init];
    
    [dict setValue: synonymsArray forKey: kVSDictKey_synonyms];
    //////////////////////////////
    NSMutableArray *collinsArray = [[NSMutableArray alloc] init];
    
    eleArray = [htmlParser searchWithXPathQuery: @"//div[@class='collins']//div[@class='collins_content']/div[@class='collins_en_cn']"];
    for (element in eleArray)
    {
        NSString *category = [[element peekAtSearchWithXPathQuery: @"//div[@class='caption']/span[@class='st']"].text trimSpaceAndReturn];
        NSString *explainCN = [[element peekAtSearchWithXPathQuery: @"//div[@class='caption']/span[@class='text_blue']"].text trimSpaceAndReturn];
        NSArray *enArray = [element searchWithXPathQuery: @"//div[@class='caption']/node()[position() > 6]"];
        
        if (category && explainCN)
        {
            if (![_collinsCategoryDict valueForKey: category])
            {
                NSString *categoryTip = [element peekAtSearchWithXPathQuery: @"//div[@class='caption']/span[@class='st']//div[@class='tips_content']"].text;
                
                if (categoryTip)
                {
                    [_collinsCategoryDict setValue: categoryTip forKey: category];
                    
                    categoryUpdated = YES;
                }
            }
            
            NSMutableString *explainEN = [[NSMutableString alloc] init];
            for (NSUInteger index = 0; index < [enArray count]; index++)
            {
                TFHppleElement *enEle = [enArray objectAtIndex: index];
                NSString *enText = enEle.text;
                NSString *tagName = enEle.tagName;
                
                if (enText)
                {
                    if (tagName && ![tagName isEqualToString: @"text"])
                        enText = [NSString stringWithFormat: @"<%@>%@</%@>", tagName, enText, tagName];
                    
                    [explainEN appendString: enText];
                }
            }
            
            NSMutableArray *samplesArray = [[NSMutableArray alloc] init];
            NSArray *sampleEleArray = [element searchWithXPathQuery: @"//ul/li"];
            for (TFHppleElement *sampleElement in sampleEleArray)
            {
                NSArray *enArray = [sampleElement searchWithXPathQuery: @"//p[1]/node()"];
                NSString *ttsURL = @"";
                NSMutableString *sampleEN = [[NSMutableString alloc] init];
                for (NSUInteger index = 0; index < [enArray count]; index++)
                {
                    TFHppleElement *enEle = [enArray objectAtIndex: index];
                    
                    NSString *tagClassName = [[enEle attributes] valueForKey: @"class"];
                    if (tagClassName && [tagClassName isEqualToString: @"ico_sound"])
                    {
                        ttsURL = [[enEle attributes] valueForKey: @"onclick"];
                        ttsURL = [ttsURL subStringAfter: @"('" before: @"')"];
                        
                        break;
                    }
                    
                    NSString *enText = enEle.text;
                    if (enText)
                        [sampleEN appendString: enText];
                }
                
                NSString *sampleCN = [[sampleElement peekAtSearchWithXPathQuery: @"//p[2]"].text trimSpaceAndReturn];
                
                if (enArray && [enArray count] > 0 && sampleCN)
                {
                    NSDictionary *sampleDict = @{kVSDictKey_explain_EN: [sampleEN trimSpaceAndReturn],
                                                 //kVSDictKey_siteURL: ttsURL,
                                                 kVSDictKey_explain_CN: sampleCN};
                    
                    [samplesArray addObject: sampleDict];
                }
            }
            
            NSDictionary *collinsExplain = @{kVSDictKey_category: category,
                                             kVSDictKey_explain_CN: explainCN,
                                             kVSDictKey_explain_EN: [explainEN trimSpaceAndReturn],
                                             kVSDictKey_samples: samplesArray};
            
            [collinsArray addObject: collinsExplain];
        }
    }
    
    [dict setValue: collinsArray forKey: kVSDictKey_Collins];
    
    if (categoryUpdated)
        [_collinsCategoryDict writeToFile: [self collinsCategoryFile: _currentSite] atomically: YES];
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
                if (![dict writeToFile: fileName atomically: YES])
                {
                    NSLog(@"Failed to writeToFile: %@", fileName);
                }
                else
                    [self deleteErrorDescription];
                    
                
//                if (![data writeToFile: fileName options: NSDataWritingAtomic error: &error])
//                {
//                    NSLog(@"Failed to writeToFile: %@", fileName);
//                    
//                    [self saveToFailList: [NSString stringWithFormat: @"Save to file fail [%ld]: %@", error.code, error.description]];
//                }
//                else
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
