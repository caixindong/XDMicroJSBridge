//
//  XDMicroJSBridge.m
//  XDMicroJSBridge
//
//  Created by 蔡欣东 on 2018/4/19.
//

#import "XDMicroJSBridge.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface XDMicroJSBridge()

@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, strong) JSContext *context;

@end

@implementation XDMicroJSBridge

+ (instancetype)bridgeForWebView:(UIWebView *)webView {
    XDMicroJSBridge *brige = [[XDMicroJSBridge alloc] init];
    [brige _setupContext:webView];
    return brige;
}

- (void)_setupContext:(UIWebView *)webView {
    _webView = webView;
    _context = [_webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    _nameSpace = @"XDMCBridge";
    _context[_nameSpace] = @{};
}

- (void)registerAction:(NSString *)action handler:(XDMCJSBHandle)handler {
    if (action && handler) {
        _context[_nameSpace][action] = ^{
            NSArray *args = [JSContext currentArguments];
            JSValue *last = (JSValue *)[args lastObject];
            XDMCJSBCallback ncallback = nil;
            NSMutableArray *trueArgs = [NSMutableArray arrayWithArray:args];
            if ([last isObject] && [[last toDictionary] isEqualToDictionary:@{}]) {
                [trueArgs removeLastObject];
                ncallback = ^(NSDictionary *params){
                    [last callWithArguments:@[params]];
                };
            }
            NSMutableArray *trueOCArgs = [NSMutableArray array];
            for (JSValue *value in trueArgs) {
                if ([value isObject]) {
                    [trueOCArgs addObject:[value toDictionary]];
                } else if ([value isString]) {
                    [trueOCArgs addObject:[value toString]];
                } else if ([value isNull]) {
                    [trueOCArgs addObject:[NSNull null]];
                } else if ([value isBoolean]) {
                    [trueOCArgs addObject:[NSNumber numberWithBool:[value toBool]]];
                }
            }
            handler([trueOCArgs copy], ncallback);
        };
    }
}

- (void)callAction:(NSString *)action param:(NSArray *)param {
    if (action && param) {
        JSValue *jsMethod = _context[action];
        [jsMethod callWithArguments:param];
    }
}

- (void)setNameSpace:(NSString *)nameSpace {
    _nameSpace = nameSpace;
    _context[_nameSpace] = @{};
}

@end
