#import "AIOLoginItem.h"

@implementation AIOLoginItem

+ (void)addAppToLoginItems {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];

	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath];

	// Create a reference to the shared file list.
  // We are adding it to the current user only.
  // If we want to add it all users, use
  // kLSSharedFileListGlobalLoginItems instead of
  //kLSSharedFileListSessionLoginItems
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		//Insert an item to the list.
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
    if(item) {
      CFRelease(item);
    }
    CFRelease(loginItems);
  }
}

+ (void)removeAppFromLoginItems {
	NSString *appPath = [[NSBundle mainBundle] bundlePath];

	// This will retrieve the path for the application
	// For example, /Applications/test.app
	CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:appPath];

	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);

	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
    CFArrayRef loginItemsArray = LSSharedFileListCopySnapshot(loginItems, &seedValue);

    if(loginItemsArray) {
      for(id loginItem in (NSArray *)loginItemsArray) {
        LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)loginItem;

        //Resolve the item with URL
        if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *) &url, NULL) == noErr) {
          NSString *urlPath = [(NSURL *)url path];
          if ([urlPath compare:appPath] == NSOrderedSame){
            LSSharedFileListItemRemove(loginItems,itemRef);
          }
        }
      }
      CFRelease(loginItemsArray);
    }
    CFRelease(loginItems);
	}
}

@end
