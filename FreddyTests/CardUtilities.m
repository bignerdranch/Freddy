//
//  CardUtilities.m
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

#import "CardUtilities.h"

NSDateFormatter *ReleaseDateFullFormatter(void) {
    static dispatch_once_t onceToken;
    static NSDateFormatter *fmt = nil;
    dispatch_once(&onceToken, ^{
        fmt = NSDateFormatter.new;
        fmt.dateFormat = @"YYYY-MM-DD";
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        fmt.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return fmt;
}

NSDateFormatter *ReleaseDateMonthFormatter(void) {
    static dispatch_once_t onceToken;
    static NSDateFormatter *fmt = nil;
    dispatch_once(&onceToken, ^{
        fmt = NSDateFormatter.new;
        fmt.dateFormat = @"YYYY-MM";
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        fmt.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return fmt;
}

NSDateFormatter *ReleaseDateYearFormatter(void) {
    static dispatch_once_t onceToken;
    static NSDateFormatter *fmt = nil;
    dispatch_once(&onceToken, ^{
        fmt = NSDateFormatter.new;
        fmt.dateFormat = @"YYYY";
        fmt.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        fmt.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    });
    return fmt;
}

NSDateComponents *ReleaseDateFromString(NSString *string, ReleaseDateKind *outKind) {
    if (!string.length) {
        return nil;
    }

    typedef NSDateFormatter *(*DateFormatterGetter)(void);
    __block NSDateFormatter *formatter = nil;
    __block NSDate *date = nil;

    BOOL(^try)(DateFormatterGetter) = ^BOOL(DateFormatterGetter getDateFormatter){
        formatter = getDateFormatter();
        date = [formatter dateFromString:string];
        return (date != nil);
    };

    if (try(ReleaseDateFullFormatter)) {
        *outKind = ReleaseDateKindFull;
        return [formatter.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitCalendar fromDate:date];
    } else if (try(ReleaseDateMonthFormatter)) {
        *outKind = ReleaseDateKindMonth;
        return [formatter.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitCalendar fromDate:date];
    } else if (try(ReleaseDateYearFormatter)) {
        *outKind = ReleaseDateKindYear;
        return [formatter.calendar components:NSCalendarUnitYear | NSCalendarUnitCalendar fromDate:date];
    } else {
        return nil;
    }
}

NSString *ReleaseDateToString(NSDateComponents *components, ReleaseDateKind kind) {
    if (!components) {
        return nil;
    }

    NSDateFormatter *formatter = nil;

    switch (kind) {
        case ReleaseDateKindNone:
            return nil;
        case ReleaseDateKindFull:
            formatter = ReleaseDateFullFormatter();
            break;
        case ReleaseDateKindMonth:
            formatter = ReleaseDateMonthFormatter();
            break;
        case ReleaseDateKindYear:
            formatter = ReleaseDateYearFormatter();
            break;
    }

    NSDate *date = [formatter.calendar dateFromComponents:components];
    return [formatter stringFromDate:date];
}
