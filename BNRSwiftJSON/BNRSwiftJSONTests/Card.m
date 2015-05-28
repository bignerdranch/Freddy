//
//  Card.m
//  BNRSwiftJSON
//
//  Created by Zachary Waldowski on 5/20/15.
//  Copyright (c) 2015 Big Nerd Ranch Inc. All rights reserved.
//

#import "Card.h"
#import "CardUtilities.h"

@implementation CardObjC

- (nullable instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (!self) { return nil; }

    id(^forceUnwrap)(NSString *) = ^(NSString *key){
        id ret = dict[key];
        NSAssert(ret != nil, @"Unexpectedly found nil while fetching value for %@", key);
        return ret;
    };

    _layout = forceUnwrap(@"layout");
    _name = forceUnwrap(@"name");
    _manaCost = dict[@"manaCost"] ?: @"";
    _cmc = dict[@"cmc"] ?: @0;
    _colors = dict[@"colors"];
    _type = forceUnwrap(@"type");
    _supertypes = dict[@"supertypes"];
    _types = dict[@"types"] ?: @[];
    _subtypes = dict[@"subtypes"];
    _rarity = forceUnwrap(@"rarity");
    _text = dict[@"text"];
    _flavor = dict[@"flavor"];
    _artist = forceUnwrap(@"artist");
    _number = dict[@"number"];
    _power = dict[@"power"];
    _toughness = dict[@"toughness"];
    _loyalty = dict[@"loyalty"];
    _multiverseID = dict[@"multiverseid"];
    _variations = dict[@"variations"];
    _watermark = dict[@"watermark"];
    _border = dict[@"border"];
    if ([dict[@"timeshifted"] boolValue]) {
        _timeshifted = YES;
    }
    _hand = dict[@"hand"];
    _life = dict[@"life"];
    if ([dict[@"reserved"] boolValue]) {
        _reserved = YES;
    }
    _releaseDate = ReleaseDateFromString(dict[@"releaseDate"], &_releaseDateKind);
    if ([dict[@"starter"] boolValue]) {
        _starter = YES;
    }

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

    result[@"layout"] = self.layout;
    result[@"name"] = self.name;
    if (self.manaCost.length != 0) {
        result[@"manaCost"] = self.manaCost;
        result[@"cmc"] = self.cmc;
    }
    setIfNotNil(@"colors", self.colors);
    result[@"type"] = self.type;
    setIfNotNil(@"supertypes", self.supertypes);
    if (self.types.count != 0) {
        result[@"types"] = self.types;
    }
    setIfNotNil(@"subtypes", self.subtypes);
    result[@"rarity"] = self.rarity;
    setIfNotNil(@"text", self.text);
    setIfNotNil(@"flavor", self.flavor);
    result[@"artist"] = self.artist;
    setIfNotNil(@"number", self.number);
    setIfNotNil(@"power", self.power);
    setIfNotNil(@"toughness", self.toughness);
    setIfNotNil(@"loyalty", self.loyalty);
    setIfNotNil(@"multiverseid", self.multiverseID);
    setIfNotNil(@"variations", self.variations);
    setIfNotNil(@"watermark", self.watermark);
    setIfNotNil(@"border", self.border);
    setIfTrue(@"timeshifted", self.timeshifted);
    setIfNotNil(@"hand", self.hand);
    setIfNotNil(@"life", self.life);
    setIfTrue(@"reserved", self.reserved);
    setIfNotNil(@"releaseDate", ReleaseDateToString(self.releaseDate, self.releaseDateKind));
    setIfTrue(@"starter", self.starter);

    return result;
}

@end
