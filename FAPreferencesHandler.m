// TODO: Improve the structure of the plist.
// It's very inneficient to keep iterating through arrays.

#import "FAPreferencesHandler.h"

static NSDictionary *FALayoutDict() {
	return [NSDictionary dictionaryWithContentsOfFile:@FALayoutPath];
}

static FAPreferencesHandler *sharedInstance_ = nil;
@implementation FAPreferencesHandler
+ (id)sharedInstance {
	if (!sharedInstance_)
		sharedInstance_ = [[FAPreferencesHandler alloc] init];
	
	return sharedInstance_;
}

- (id)init {
	if ((self = [super init])) {
		id cache = [FALayoutDict() objectForKey:@"FAFolderCache"];
		NSMutableArray *arr = nil;
		
		// Perform conversion from old v1.0 plists.
		if ([cache isKindOfClass:[NSDictionary class]]) {
			arr = [NSMutableArray array];
			
			NSMutableDictionary *convert = [NSMutableDictionary dictionary];
			NSArray *allKeys = [cache allKeys];
			for (NSString *k in allKeys) {
				NSDictionary *d = [cache objectForKey:k];
				[convert setObject:k forKey:@"keyTitle"];
				if (([d objectForKey:@"fakeTitle"]))
					[convert setObject:[d objectForKey:@"fakeTitle"] forKey:@"fakeTitle"];
				[convert setObject:[d objectForKey:@"listIndex"] forKey:@"listIndex"];
				[convert setObject:[d objectForKey:@"iconIndex"] forKey:@"iconIndex"];
				[convert setObject:[d objectForKey:@"mediaCollection"] forKey:@"mediaCollection"];
				
				[arr addObject:convert];
			}
			
			NSMutableDictionary *_dict = [NSMutableDictionary dictionaryWithDictionary:FALayoutDict()];
			[_dict setObject:arr forKey:@"FAFolderCache"];
			[_dict writeToFile:@FALayoutPath atomically:YES];
		}
		
		_cache = arr ? [arr retain] : [[NSMutableArray arrayWithArray:cache] retain];
	}
	
	return self;
}

- (void)dealloc {
	[_cache release];
	[super dealloc];
}

- (BOOL)keyExists:(NSString *)key {
	for (NSDictionary *dict in _cache) {
		if ([[dict objectForKey:@"keyTitle"] isEqualToString:key])
			return YES;
	}
	
	return NO;
}

- (NSArray *)allKeys {
	return _cache;
}

- (id)objectForKey:(NSString *)key {
	if (![self keyExists:key])
		return nil;
	
	for (NSDictionary *dict in _cache) {
		if ([[dict objectForKey:@"keyTitle"] isEqualToString:key])
			return dict;
	}
	
	return nil;
}

- (void)updateKey:(NSString *)key withDictionary:(NSDictionary *)dict {
	NSUInteger i;
	for (i=0; i<[_cache count]; i++) {
		if ([[[_cache objectAtIndex:i] objectForKey:@"keyTitle"] isEqualToString:key]) {
			[_cache replaceObjectAtIndex:i withObject:dict];
			goto write;
		}
	}
	
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:dict];
	[d setObject:key forKey:@"keyTitle"];
	[_cache addObject:d];
	
	write:
	[self _writeCacheToFile];
}

- (void)optimizedUpdateKey:(NSString *)key withDictionary:(NSDictionary *)dict {
	NSArray *keys = [dict allKeys];
	
	NSDictionary *_tgt = [self objectForKey:key];
	if (!_tgt) return;
	
	NSMutableDictionary *tgt = [NSMutableDictionary dictionaryWithDictionary:_tgt];
	for (NSString *k in keys)
		[tgt setObject:[dict objectForKey:k] forKey:k];
		
	[self updateKey:key withDictionary:tgt];
}

- (void)deleteKey:(NSString *)key {
	for (NSDictionary *dict in _cache) {
		if ([[dict objectForKey:@"keyTitle"] isEqualToString:key]) {
			[_cache removeObject:dict];
			break;
		}
	}
	
	[self _writeCacheToFile];
}

- (void)_writeCacheToFile {
	NSMutableDictionary *_dict = [NSMutableDictionary dictionaryWithDictionary:FALayoutDict()];
	
	[_dict setObject:_cache forKey:@"FAFolderCache"];
	[_dict writeToFile:@FALayoutPath atomically:YES];
}
@end