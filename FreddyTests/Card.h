//
//  Card.h
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

@import Foundation;
#import "CardUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface CardObjC : NSObject

@property (nonatomic, copy, readonly) NSString *layout;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *manaCost;
@property (nonatomic, readonly) NSNumber *cmc;
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *colors;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *supertypes;
@property (nonatomic, copy, readonly) NSArray<NSString *> *types;
@property (nonatomic, copy, readonly, nullable) NSArray<NSString *> *subtypes;
@property (nonatomic, copy, readonly) NSString *rarity;
@property (nonatomic, copy, readonly, nullable) NSString *text;
@property (nonatomic, copy, readonly, nullable) NSString *flavor;
@property (nonatomic, copy, readonly) NSString *artist;
@property (nonatomic, copy, readonly, nullable) NSString *number;
@property (nonatomic, copy, readonly, nullable) NSString *power;
@property (nonatomic, copy, readonly, nullable) NSString *toughness;
@property (nonatomic, copy, readonly, nullable) NSString *loyalty;
@property (nonatomic, readonly, nullable) NSNumber *multiverseID;
@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *variations;
@property (nonatomic, readonly, nullable) NSString *watermark;
@property (nonatomic, readonly, nullable) NSString *border;
@property (nonatomic, readonly, getter=isTimeshifted) BOOL timeshifted;
@property (nonatomic, readonly, nullable) NSNumber *hand;
@property (nonatomic, readonly, nullable) NSNumber *life;
@property (nonatomic, readonly, getter=isReserved) BOOL reserved;
@property (nonatomic, readonly) ReleaseDateKind releaseDateKind;
@property (nonatomic, readonly, nullable) NSDateComponents *releaseDate;
@property (nonatomic, readonly, getter=isStarter) BOOL starter;

- (nullable instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary NS_DESIGNATED_INITIALIZER;
@property (nonatomic, copy) NSDictionary<NSString *, id> *dictionaryValue;

@end

NS_ASSUME_NONNULL_END
