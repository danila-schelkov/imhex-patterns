#pragma description Supercell file
#pragma magic [ 53 43 ] @ 0x00
#pragma endian big

#ifdef __IMHEX__
    import hex.dec;
#endif

#pragma pattern_limit 10485760

import fbs;
import type.magic;
import std.mem;
import * from zstd as Zstd;

bool evaluate_decompression in;
bool export_section in;

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

struct ExternalMatrixBank {
    RootTable table;
    
    Optional<u32, table, 0> index;
    Field<u32, table, 1, 0> offset;  // compressed_offset
    Optional<u32, table, 2> size;  // compressed_size
    Optional<u32, table, 3> decompressed_size;
    Optional<u32, table, 4> u5;  // count of zeros
    Optional<u32, table, 5> u6;
    Optional<u32, table, 6> short_matrix_count;
    Optional<u32, table, 7> float_matrix_count;
    Optional<u32, table, 8> color_transform_count;
    Optional<u32, table, 9> u10;  // some offset, same as decompressed_size
    Optional<u32, table, 10> u11;
    Optional<u32, table, 11> u12;  // something like load immediately
    Optional<u32, table, 12> always_10;  // always 10, 21 in lib if u12 is set
};

struct ExternalMatrixBanks {
    RootTable table;
    
    OptionalPtr<Vector<ExternalMatrixBank>, table, 0> matrix_banks;
};

u32 index = 0;

struct ExternalMatrixBankContent<auto MatrixBankVector> {
    Zstd zstd @ $ + MatrixBankVector.values[index].offset.value [[inline]];
    
#ifdef __IMHEX__
    if (export_section) {
        // From https://github.com/WerWolv/ImHex-Patterns/blob/0b753366383ef2dac479581d9fb12c4d6802a992/patterns/blend.hexpat#L182
        std::mem::Section decompressed_section = std::mem::create_section("decompressed");
        std::assert(hex::dec::zstd_decompress(zstd, decompressed_section), "Decompression failed!");
        
        u128 current_section_size = std::mem::get_section_size(decompressed_section);
        u8 decompressed[current_section_size] @ 0x00 in decompressed_section;
    }
#endif
    
    // last block
    // matrix2x3 - 7th field is count (f32 x6 (abcdxy))
    // unk zeros 4th (from zero) field (f32 or u32/i32 or u8 x4)
    // short matrices
    // 8 extra zeros
    // color transforms
    // align bytes
    
    index += 1;
    
    if (index >= MatrixBankVector.count) {
        break;
    }
};

struct ScFile {
    type::Magic<"SC"> magic;
    u32 version;
    if (version == 4) {
        u32 compression_type;
    } else {
        u32 compression_type = version;
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
        NestedFlatbuffer<Metadata> metadata;
    }
    
    if (evaluate_decompression) {
        if (compression_type == 1) {
            // todo: lzma
        } else {
            Zstd zstd;

        #ifdef __IMHEX__
            if (export_section) {
                // From https://github.com/WerWolv/ImHex-Patterns/blob/0b753366383ef2dac479581d9fb12c4d6802a992/patterns/blend.hexpat#L182
                std::mem::Section decompressed_section = std::mem::create_section("decompressed");
                std::assert(hex::dec::zstd_decompress(zstd, decompressed_section), "Decompression failed!");
                
                u128 current_section_size = std::mem::get_section_size(decompressed_section);
                u8 decompressed[current_section_size] @ 0x00 in decompressed_section;
                // SupercellSWF swf @ 0x00 in decompressedSection;
            }
        #endif
        }
    } else {
        // TODO: run only if metadata exists (version is compatible)
        padding[metadata.value.compressed_size.value];
    }
    
    if (metadata.value.matrices_size.field_address != std::limits::u64_max()) {
        NestedFlatbuffer<ExternalMatrixBanks> external_matrix_banks;
        
        if (evaluate_decompression) {
            // solution, but pretty bad
            ExternalMatrixBankContent<external_matrix_banks.value.matrix_banks.value.value> content[while(!std::mem::eof())];
        }
    }
};

ScFile file @ 0x00;
