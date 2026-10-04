#import "ZipExtractor.h"
#import <zlib.h>

@implementation ZipExtractor
static uint16_t rd16(const uint8_t *p) { return (uint16_t)p[0] | ((uint16_t)p[1] << 8); }
static uint32_t rd32(const uint8_t *p) { return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24); }

+ (BOOL)extractArchiveAtPath:(NSString *)archivePath toDirectory:(NSString *)destination error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfFile:archivePath options:NSDataReadingMappedIfSafe error:error];
    if (!data) return NO;
    const uint8_t *b = data.bytes; NSUInteger n = data.length;
    if (n < 22) return NO;

    // Find End Of Central Directory (EOCD) in the final 64 KiB + record size.
    NSInteger min = (NSInteger)MAX((NSUInteger)0, n > 65557 ? n - 65557 : 0);
    NSInteger eocd = -1;
    for (NSInteger i = (NSInteger)n - 22; i >= min; i--) {
        if (rd32(b + i) == 0x06054b50) { eocd = i; break; }
    }
    if (eocd < 0) {
        if (error) *error = [NSError errorWithDomain:@"PanelReader.Zip" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Invalid CBZ/ZIP archive."}];
        return NO;
    }
    uint16_t entries = rd16(b + eocd + 10);
    uint32_t cdOffset = rd32(b + eocd + 16);
    NSUInteger pos = cdOffset;
    NSFileManager *fm = NSFileManager.defaultManager;
    [fm createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:nil];

    for (uint16_t e = 0; e < entries; e++) {
        if (pos + 46 > n || rd32(b + pos) != 0x02014b50) break;
        uint16_t method = rd16(b + pos + 10);
        uint32_t compressedSize = rd32(b + pos + 20);
        uint32_t uncompressedSize = rd32(b + pos + 24);
        uint16_t nameLen = rd16(b + pos + 28);
        uint16_t extraLen = rd16(b + pos + 30);
        uint16_t commentLen = rd16(b + pos + 32);
        uint32_t localOffset = rd32(b + pos + 42);
        if (pos + 46 + nameLen + extraLen + commentLen > n) break;

        NSData *nameData = [NSData dataWithBytes:b + pos + 46 length:nameLen];
        NSString *name = [[NSString alloc] initWithData:nameData encoding:NSUTF8StringEncoding] ?: [[NSString alloc] initWithData:nameData encoding:NSISOLatin1StringEncoding];
        pos += 46 + nameLen + extraLen + commentLen;
        if (!name || [name hasPrefix:@"/"]) continue;

        NSString *normalized = [name stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        NSArray<NSString *> *parts = [normalized componentsSeparatedByString:@"/"];
        NSMutableArray<NSString *> *clean = [NSMutableArray array];
        BOOL unsafe = NO;
        for (NSString *part in parts) {
            if ([part isEqualToString:@".."] || [part hasPrefix:@"~"]) { unsafe = YES; break; }
            if (part.length && ![part isEqualToString:@"."]) [clean addObject:part];
        }
        if (unsafe || clean.count == 0) continue;
        NSString *outPath = destination;
        for (NSString *part in clean) outPath = [outPath stringByAppendingPathComponent:part];
        if ([normalized hasSuffix:@"/"]) {
            [fm createDirectoryAtPath:outPath withIntermediateDirectories:YES attributes:nil error:nil];
            continue;
        }

        if ((NSUInteger)localOffset + 30 > n || rd32(b + localOffset) != 0x04034b50) continue;
        uint16_t localNameLen = rd16(b + localOffset + 26);
        uint16_t localExtraLen = rd16(b + localOffset + 28);
        NSUInteger payload = (NSUInteger)localOffset + 30 + localNameLen + localExtraLen;
        if (payload + compressedSize > n) continue;
        [fm createDirectoryAtPath:[outPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];

        NSData *out = nil;
        if (method == 0) {
            out = [NSData dataWithBytes:b + payload length:compressedSize];
        } else if (method == 8) {
            NSMutableData *decoded = [NSMutableData dataWithLength:uncompressedSize];
            z_stream s = {0}; s.next_in = (Bytef *)(b + payload); s.avail_in = compressedSize; s.next_out = decoded.mutableBytes; s.avail_out = uncompressedSize;
            if (inflateInit2(&s, -MAX_WBITS) != Z_OK) return NO;
            int rc = inflate(&s, Z_FINISH); inflateEnd(&s);
            if (rc != Z_STREAM_END) {
                if (error) *error = [NSError errorWithDomain:@"PanelReader.Zip" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Could not decompress a CBZ page."}];
                return NO;
            }
            decoded.length = s.total_out; out = decoded;
        } else {
            continue; // Ignore non-image metadata compressed with unsupported methods.
        }
        if (out && ![out writeToFile:outPath options:NSDataWritingAtomic error:error]) return NO;
    }
    return YES;
}
@end
