//
//  CardUtilities.h
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ReleaseDateKind) {
    ReleaseDateKindNone,
    ReleaseDateKindFull,
    ReleaseDateKindMonth,
    ReleaseDateKindYear
};

extern NSDateFormatter *ReleaseDateFullFormatter(void);
extern NSDateFormatter *ReleaseDateMonthFormatter(void);
extern NSDateFormatter *ReleaseDateYearFormatter(void);
extern NSDateComponents *_Nullable ReleaseDateFromString(NSString *string, ReleaseDateKind *outKind);
extern NSString *ReleaseDateToString(NSDateComponents *components, ReleaseDateKind kind);

NS_ASSUME_NONNULL_END
