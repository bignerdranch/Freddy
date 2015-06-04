//
//  CardSet.m
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

#import "CardSet.h"
#import "Card.h"

@implementation CardSetObjC

+ (NSArray *)cardSetsFromDictionaries:(NSArray *)cardSetDicts
{
    NSMutableArray *cardSets = [[NSMutableArray alloc] initWithCapacity:cardSetDicts.count];
    for (NSDictionary *dict in cardSetDicts) {
        CardSetObjC *next = [[CardSetObjC alloc] initWithDictionary:dict];
        if (next == nil) {
            return nil;
        }
        [cardSets addObject:next];
    }
    return cardSets;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (!self) { return nil; }

    id(^forceUnwrap)(NSString *) = ^(NSString *key){
        id ret = dict[key];
        NSAssert(ret != nil, @"Unexpectedly found nil while fetching value for %@", key);
        return ret;
    };

    _name = forceUnwrap(@"name");
    _code = forceUnwrap(@"code");
    _gathererCode = dict[@"gathererCode"];
    _oldCode = dict[@"oldCode"];
    _magicCardsInfoCode = dict[@"magicCardsInfoCode"];

    ReleaseDateKind kind;
    NSDateComponents *comp = ReleaseDateFromString(dict[@"releaseDate"], &kind);
    NSAssert(kind == ReleaseDateKindFull, @"Unexpected date format");
    _releaseDate = comp.date;

    _border = forceUnwrap(@"border");
    _type = forceUnwrap(@"type");
    _block = dict[@"block"];
    if ([dict[@"onlineOnly"] boolValue]) {
        _onlineOnly = YES;
    }
    _booster = dict[@"booster"] ?: @[];

    NSArray *cardDicts = forceUnwrap(@"cards");
    NSMutableArray *cards = [[NSMutableArray alloc] initWithCapacity:cardDicts.count];
    for (NSDictionary *dict in cardDicts) {
        CardObjC *next = [[CardObjC alloc] initWithDictionary:dict];
        NSAssert(@"Unexpectedly found nil while converting value to %@", NSStringFromClass(CardObjC.self));
        [cards addObject:next];
    }
    _cards = cards;

    return self;

}

- (NSDictionary *)dictionaryValue {
    NSMutableDictionary *result = NSMutableDictionary.new;

    BOOL(^setIfNotNil)(NSString *, id) = ^(NSString *key, id value) {
        if (value == nil) {
            return NO;
        }
        result[key] = value;
        return YES;
    };

    BOOL(^setIfTrue)(NSString *, BOOL) = ^(NSString *key, BOOL value) {
        if (!value) {
            return NO;
        }
        result[key] = value ? @YES : @NO;
        return YES;
    };

    result[@"name"] = self.name;
    result[@"code"] = self.code;
    setIfNotNil(@"gathererCode", self.gathererCode);
    setIfNotNil(@"oldCode", self.oldCode);
    setIfNotNil(@"magicCardsInfoCode", self.magicCardsInfoCode);
    result[@"releaseDate"] = [ReleaseDateFullFormatter() stringFromDate:self.releaseDate];
    result[@"border"] = self.border;
    result[@"type"] = self.type;
    setIfNotNil(@"block", self.block);
    setIfTrue(@"onlineOnly", self.onlineOnly);
    if (self.booster.count != 0) {
        result[@"booster"] = self.booster;
    }

    NSMutableArray *cardDicts = [[NSMutableArray alloc] initWithCapacity:self.cards.count];
    for (CardObjC *card in self.cards) {
        [cardDicts addObject:card.dictionaryValue];
    }
    result[@"cards"] = cardDicts;

    return result;

}

@end
