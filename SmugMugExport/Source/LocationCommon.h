
@interface LocationCommon : NSObject
{
}

+ (id)descriptionForPlace:(id)fp8;
+ (void)stringToLatLng:(id)fp8 lat:(float *)fp12 lng:(float *)fp16;
+ (double)distanceFrom:(double)fp8 lng1:(double)fp16 lat2:(double)fp24 lng2:(double)fp32;
+ (struct _NSPoint)locationAlongLatitudeOfGivenDistance:(float)fp8 fromCoordinate:(struct _NSPoint)fp12;
+ (struct _NSRect)mapRectCenteredOnCoordinate:(struct _NSPoint)fp8 withRadius:(float)fp16;
+ (struct _NSPoint)pixelCoordinatesForGPSLocation:(struct _NSPoint)fp8 inMapBounds:(struct _NSRect)fp16 withFrame:(struct _NSRect)fp32;
+ (struct _NSPoint)gpsCoordinatesForPixelLocation:(struct _NSPoint)fp8 inMapBounds:(struct _NSRect)fp16 withFrame:(struct _NSRect)fp32;
+ (void)addFormattedStringsForAddress:(id)fp8 includePersonOrPlace:(BOOL)fp12;
+ (id)itemLabelForIndex:(int)fp8;
+ (void)addGeoHierarchy:(id)fp8 inDB:(id)fp12;
+ (int)getPrimaryKeyForGeoType:(id)fp8 inDB:(id)fp12;
+ (void)setLocationForPhoto:(struct IPPhotoInfo *)fp8 fromDict:(id)fp12 name:(id)fp16 preserveExistingData:(BOOL)fp20;
+ (void)setLocationForDevicePhoto:(struct IPPhotoInfo *)fp8 fromDict:(id)fp12 name:(id)fp16 preserveExistingData:(BOOL)fp20;
+ (void)setLocationForPhoto:(struct IPPhotoInfo *)fp8 fromHierarchy:(id)fp12 name:(id)fp16 preserveExistingData:(BOOL)fp20;
+ (void)setLocationForPhoto:(struct IPPhotoInfo *)fp8 fromUserPlaceKey:(unsigned int)fp12;
+ (id)inheritedlocationDictFromPhoto:(struct IPPhotoInfo *)fp8;
+ (id)locationDictFromPhoto:(struct IPPhotoInfo *)fp8;
+ (id)searchDictFromPhoto:(struct IPPhotoInfo *)fp8;
+ (void)setLocationForRoll:(struct IPRoll *)fp8 fromDict:(id)fp12 name:(id)fp16 preserveExistingData:(BOOL)fp20;
+ (void)setLocationForRoll:(struct IPRoll *)fp8 fromHierarchy:(id)fp12 name:(id)fp16 preserveExistingData:(BOOL)fp20;
+ (void)setLocationForRoll:(struct IPRoll *)fp8 fromUserPlaceKey:(unsigned int)fp12;
+ (id)locationDictFromRoll:(struct IPRoll *)fp8;
+ (id)searchDictFromRoll:(struct IPRoll *)fp8;
+ (void)assignLocationDict:(id)fp8 toRoll:(struct IPRoll *)fp12;
+ (id)locationForiegnKeyDictFromPhoto:(struct IPPhotoInfo *)fp8;
+ (void)assignLocationForiegnKeyDict:(id)fp8 toPhoto:(struct IPPhotoInfo *)fp12;
+ (void)recomputeLocationBoundsForEvent:(struct IPRoll *)fp8;
+ (void)determineLocationForEventIfNecessary:(struct IPRoll *)fp8;
+ (void)determineLocationForEvent:(struct IPRoll *)fp8 photos:(struct IPPhotoList *)fp12;
+ (int)predominantCountryForPhotos:(struct IPPhotoList *)fp8;
+ (int)predominantProvinceForPhotos:(struct IPPhotoList *)fp8;
+ (int)predominantCountyForPhotos:(struct IPPhotoList *)fp8;
+ (int)predominantCityForPhotos:(struct IPPhotoList *)fp8;
+ (int)predominantNeighborhoodForPhotos:(struct IPPhotoList *)fp8;
+ (int)predominantAOIForPhotos:(struct IPPhotoList *)fp8;
+ (int)predominantPOIForPhotos:(struct IPPhotoList *)fp8;
+ (BOOL)gpsDataExistsForPhotos:(struct IPPhotoList *)fp8;
+ (id)queryStringByParsingString:(id)fp8;
+ (id)userDefaultCity;

@end

