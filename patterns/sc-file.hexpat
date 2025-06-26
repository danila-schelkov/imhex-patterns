#pragma description Supercell file
#pragma magic [ 53 43 ] @ 0x00
#pragma endian big

#ifdef __IMHEX__
    import hex.dec;
#endif

import fbs;
import type.magic;
import * from zstd as Zstd;

bool evaluate_decompression in;
bool export_section in;

fn relative_to_table(u128 offset) {
    std::print("{} {}\n", addressof(parent), addressof(parent) - offset);
    return addressof(parent) - offset;
};

struct String {
    u32 length;
    char content[length];
} [[format_read("format_string_read"), sealed]];

fn format_string_read(ref String string) {
    return std::format("{}", string.content);
};

struct Export {
    RootTable table;
    
    OptionalPtr<String, table, 0> name;
    OptionalPtr<Vector<u8>, table, 1> hash;  // fnv afaik
} [[format_read("format_export")]];

fn format_export(ref Export export) {
    return std::format("{}", export.name.value);
};

struct Metadata {
    RootTable table;
    std::print("{}", addressof(table.vtable));
    
    Optional<u32, table, 0> translation_precision;
    Optional<u32, table, 1> scale_precision;
    Optional<u32, table, 2> shape_count;
    Optional<u32, table, 3> movie_clip_count;
    Optional<u32, table, 4> texture_count;
    Optional<u32, table, 5> text_field_count;
    Optional<u32, table, 6> u6;
    Optional<u32, table, 7> resources_offset;
    Optional<u32, table, 8> objects_offset;
    Optional<u32, table, 9> texture_chunk_length;
    OptionalPtr<Vector<Export>, table, 10> exports;
    Optional<u32, table, 11> compressed_size;
    Optional<u32, table, 12> matrices_size;
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
        
        // Note: fixed_size attribute doesn't pad the cursor, 
        // so I have to manually move it using padding expression
        // TODO: maybe export as section instead
        Metadata metadata;
        padding[size - sizeof(metadata)];
    }
    
    if (evaluate_decompression) {
        if (compressionType == 1) {
            // todo: lzma
        } else {
            Zstd zstd;

        #ifdef __IMHEX__
            if (export_section) {
                // From https://github.com/WerWolv/ImHex-Patterns/blob/0b753366383ef2dac479581d9fb12c4d6802a992/patterns/blend.hexpat#L182
                std::mem::Section decompressedSection = std::mem::create_section("decompressed");
                std::assert(hex::dec::zstd_decompress(zstd, decompressedSection), "Decompression failed!");
                
                u128 currentSectionSize = std::mem::get_section_size(decompressedSection);
                u8 decompressed[currentSectionSize] @ 0x00 in decompressedSection;
            }
        #endif
       }
   }
};

ScFile file @ 0x00;