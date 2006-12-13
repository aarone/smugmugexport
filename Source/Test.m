#import <Cocoa/Cocoa.h>

#import "NSStringAdditions.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *aStringToMatchAgainst = @"aAaAaAbBbBbBaAaA";
	CompiledRegex *r = [CompiledRegex compiledRegexWithString:@"^[aA]+([bB]+)[aA]+$"];
	NSLog(@"%@", [aStringToMatchAgainst matchWithRegularExpression:r replaceWith:@"ee"]);
	[pool release];
	return 0;
}
