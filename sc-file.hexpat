#pragma magic [ 53 43 ] @ 0x00
#pragma endian big

#ifdef __IMHEX__
    import hex.dec;
#endif

import type.magic;
import * from zstd as Zstd;

struct Metadata {

};

struct ScFile {
    type::Magic<"SC"> magic;
    u32 version;
    if (version == 4) {
        u32 compressionType;
    } else {
        u32 compressionType = version;
    }

    if (version > 4) {
        #pragma endian little
    }
    
    if (version == 6) {
        u16 u;
    }
    
    if (version <= 4) {
        u32 hash_length;
        u8 hash[hash_length];
    } else {
        u32 size;
        Metadata metadata;
        u8 metadata1[size];
    }
    
    if (compressionType == 1) {
        // todo: lzma
    } else {
        Zstd zstd;

#ifdef __IMHEX__
        // From https://github.com/WerWolv/ImHex-Patterns/blob/0b753366383ef2dac479581d9fb12c4d6802a992/patterns/blend.hexpat#L182
        std::mem::Section decompressedSection = std::mem::create_section("decompressed");
        std::assert(hex::dec::zstd_decompress(zstd, decompressedSection), "Decompression failed!");
        
        u128 currentSectionSize = std::mem::get_section_size(decompressedSection);
        u8 decompressed[currentSectionSize] @ 0x00 in decompressedSection;
#endif
   }
};

ScFile file @ 0x00;