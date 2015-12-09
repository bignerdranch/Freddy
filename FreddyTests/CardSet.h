//
//  CardSet.h
//  FreddyTests
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

@import Foundation;
@class CardObjC;

NS_ASSUME_NONNULL_BEGIN

@interface CardSetObjC : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *code;
@property (nonatomic, copy, readonly, nullable) NSString *gathererCode;
@property (nonatomic, copy, readonly, nullable) NSString *oldCode;
@property (nonatomic, copy, readonly, nullable) NSString *magicCardsInfoCode;
@property (nonatomic, readonly) NSDate *releaseDate;
@property (nonatomic, copy, readonly) NSString *border;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly, nullable) NSString *block;
@property (nonatomic, readonly, getter=isOnlineOnly) BOOL onlineOnly;
@property (nonatomic, copy, readonly) NSArray<NSString *> *booster;
@property (nonatomic, copy, readonly) NSArray<CardObjC *> *cards;

+ (nullable NSArray<CardSetObjC *> *)cardSetsFromDictionaries:(NSArray<NSDictionary<NSString *, id> *> *)cardSetDicts;

- (nullable instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary NS_DESIGNATED_INITIALIZER;
@property (nonatomic, copy) NSDictionary<NSString *, id> *dictionaryValue;

@end

NS_ASSUME_NONNULL_END
