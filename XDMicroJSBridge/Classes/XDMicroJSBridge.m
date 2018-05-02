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

@property (nonatomic, strong) NSThread *webThread;

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
    //解决callback同步问题（会阻塞线程）
    [_context evaluateScript:@"function asyncallback(callback,params) {if(typeof callback == 'function'){setTimeout(function () {callback(params);},0);}}"];
}

- (void)registerAction:(NSString *)action handler:(XDMCJSBHandle)handler {
    if (action && handler) {
        __weak typeof(self) weakSelf = self;
        _context[_nameSpace][action] = ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.webThread = [NSThread currentThread];
            NSLog(@"webThread is %@",[NSThread currentThread]);
            NSArray *args = [JSContext currentArguments];
            JSValue *last = (JSValue *)[args lastObject];
            XDMCJSBCallback ncallback = nil;
            NSMutableArray *trueArgs = [NSMutableArray arrayWithArray:args];
            if ([last isObject] && [[last toDictionary] isEqualToDictionary:@{}]) {
                [trueArgs removeLastObject];
                ncallback = ^(NSDictionary *params){
                    //如果在其他线程回调callback可能会有野指针carsh，所以callback执行需要回到webThread
                    [strongSelf performSelector:@selector(_callJSMethodWithArgs:) onThread:strongSelf.webThread withObject:@[last, params] waitUntilDone:NO];
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

- (void)_callJSMethodWithArgs:(NSArray *)args {
    if (args) {
        NSLog(@"callback thread is %@",[NSThread currentThread]);
        JSValue *async = _context[@"asyncallback"];
        [async callWithArguments:args];
    }
}

- (void)callAction:(NSString *)action param:(NSDictionary *)param {
    if (action && param) {
        JSValue *jsMethod = _context[action];
        [self _callJSMethodWithArgs:@[jsMethod, param]];
    }
}

- (void)setNameSpace:(NSString *)nameSpace {
    _nameSpace = nameSpace;
    _context[_nameSpace] = @{};
}

@end
