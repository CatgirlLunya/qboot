const std = @import("std");
const file = @import("file.zig");

// All done according to https://wiki.osdev.org/Ext2

pub const CommonSuperblock = extern struct {
    total_inodes: u32,
    total_blocks: u32,
    total_superuser_blocks: u32,
    total_unallocated_blocks: u32,
    total_unallocated_inodes: u32,
    superblock_block_number: u32,
    shifted_block_size: u32,
    shifted_fragment_size: u32,
    blocks_per_group: u32,
    fragments_per_group: u32,
    inodes_per_group: u32,
    last_mount_time: u32,
    last_written_time: u32,
    mounted_since_checked: u16,
    allowed_before_check: u16,
    ext2_signature: u16, // Should be 0xEF53
    fs_state: u16, // 1 for clean, 2 for errors
    error_hanlde: u16, // 1 is ignore, 2 is remount as read only, 3 is kernel panic
    minor_version: u16,
    last_check: u32,
    interval_between_checks: u32,
    os_id: u32, // 0 is Linux, 1 is HURD, 2 is MASIX, 3 is FreeBSD, 4 is lites
    major_version: u32,
    user_id_for_reserved_blocks: u16,
    group_id_for_reserved_blocks: u16,

    pub fn readFromBinary(bin: []u8) !CommonSuperblock {
        var block: CommonSuperblock = undefined;
        if (bin.len < 84) return error.BufferTooSmall;
        block.total_inodes = std.mem.readIntLittle(u32, bin[0..4]);
        block.total_blocks = std.mem.readIntLittle(u32, bin[4..8]);
        block.total_superuser_blocks = std.mem.readIntLittle(u32, bin[8..12]);
        block.total_unallocated_blocks = std.mem.readIntLittle(u32, bin[12..16]);
        block.total_unallocated_inodes = std.mem.readIntLittle(u32, bin[16..20]);
        block.superblock_block_number = std.mem.readIntLittle(u32, bin[20..24]);
        block.shifted_block_size = std.mem.readIntLittle(u32, bin[24..28]);
        block.shifted_fragment_size = std.mem.readIntLittle(u32, bin[28..32]);
        block.blocks_per_group = std.mem.readIntLittle(u32, bin[32..36]);
        block.fragments_per_group = std.mem.readIntLittle(u32, bin[36..40]);
        block.inodes_per_group = std.mem.readIntLittle(u32, bin[40..44]);
        block.last_mount_time = std.mem.readIntLittle(u32, bin[44..48]);
        block.last_written_time = std.mem.readIntLittle(u32, bin[48..52]);
        block.mounted_since_checked = std.mem.readIntLittle(u16, bin[52..54]);
        block.allowed_before_check = std.mem.readIntLittle(u16, bin[54..56]);
        block.ext2_signature = std.mem.readIntLittle(u16, bin[56..58]);
        block.fs_state = std.mem.readIntLittle(u16, bin[58..60]);
        block.error_hanlde = std.mem.readIntLittle(u16, bin[60..62]);
        block.minor_version = std.mem.readIntLittle(u16, bin[62..64]);
        block.last_check = std.mem.readIntLittle(u32, bin[64..68]);
        block.interval_between_checks = std.mem.readIntLittle(u32, bin[68..72]);
        block.os_id = std.mem.readIntLittle(u32, bin[72..76]);
        block.major_version = std.mem.readIntLittle(u32, bin[76..80]);
        block.user_id_for_reserved_blocks = std.mem.readIntLittle(u16, bin[80..82]);
        block.group_id_for_reserved_blocks = std.mem.readIntLittle(u16, bin[82..84]);
        return block;
    }
};

pub const ExtendedSuperblock = extern struct {
    first_non_reserved_inode: u32,
    inode_size: u16,
    superblock_block_group: u16,
    optional_features_present: u32,
    required_features_present: u32,
    read_only_features: u32,
    fs_id: u128,
    volume_name: [16:0]u8,
    path_last_mounted_to: [64:0]u8,
    compression_algorithms_used: u32,
    file_preallocation_blocks: u8,
    dir_preallocation_blocks: u8,
    journal_id: u128,
    journal_inode: u32,
    journal_device: u32,
    orphan_inode_list_head: u32,

    pub fn readFromBinary(bin: []u8) !ExtendedSuperblock {
        var block: ExtendedSuperblock = undefined;
        if (bin.len < 152) return error.BufferTooSmall;
        block.first_non_reserved_inode = std.mem.readIntNative(u32, bin[0..4]);
        block.inode_size = std.mem.readIntNative(u16, bin[4..6]);
        block.superblock_block_group = std.mem.readIntNative(u16, bin[6..8]);
        block.optional_features_present = std.mem.readIntNative(u32, bin[8..12]);
        block.required_features_present = std.mem.readIntNative(u32, bin[12..16]);
        block.read_only_features = std.mem.readIntNative(u32, bin[16..20]);
        block.fs_id = std.mem.readIntNative(u128, bin[20..36]);
        @memcpy(@as([]u8, @ptrCast(&block.volume_name)), bin[36..52]);
        @memcpy(@as([]u8, @ptrCast(&block.path_last_mounted_to)), bin[52..116]);
        block.compression_algorithms_used = std.mem.readIntNative(u32, bin[116..120]);
        block.file_preallocation_blocks = bin[120];
        block.dir_preallocation_blocks = bin[121];
        // Skip 2 for unused
        block.journal_id = std.mem.readIntNative(u128, bin[124..140]);
        block.compression_algorithms_used = std.mem.readIntNative(u32, bin[140..144]);
        block.compression_algorithms_used = std.mem.readIntNative(u32, bin[144..148]);
        block.compression_algorithms_used = std.mem.readIntNative(u32, bin[148..152]);
        return block;
    }
};

pub const Error = error{
    CorruptedSignature,
    MismatchedBlockGroups,
    BufferTooSmall,
} || std.mem.Allocator.Error;

pub const Superblock = struct {
    common: CommonSuperblock,
    extended: ?ExtendedSuperblock,

    pub const binary_size = 236;

    pub fn blockGroups(self: *Superblock) !u32 {
        const block_block_groups = @divFloor(self.common.total_blocks + self.common.blocks_per_group - 1, self.common.blocks_per_group);
        const inode_block_groups = @divFloor(self.common.total_inodes + self.common.inodes_per_group - 1, self.common.inodes_per_group);
        return if (block_block_groups == inode_block_groups) block_block_groups else error.MismatchedBlockGroups;
    }

    pub fn blockSize(self: *Superblock) u64 {
        return @as(u32, 1024) << @intCast(self.common.shifted_block_size);
    }

    pub fn blockGroupDescriptorTableStart(self: *Superblock) u64 {
        const block_size = self.blockSize();
        return block_size + self.common.superblock_block_number * block_size; // table occupies second block, so add block size to super block base to get its base
    }

    pub fn inodeSize(self: *Superblock) u32 {
        return if (self.common.major_version >= 1) self.extended.?.inode_size else Inode.binary_size;
    }

    pub fn readFromBinary(bin: []u8) !Superblock {
        var block: Superblock = undefined;
        if (bin.len < 236) return error.BufferTooSmall;
        block.common = try CommonSuperblock.readFromBinary(bin[0..]);
        if (block.common.ext2_signature != 0xEF53) {
            return error.CorruptedSignature;
        }
        if (block.common.major_version >= 1) {
            block.extended = try ExtendedSuperblock.readFromBinary(bin[84..]);
        }
        return block;
    }
};

pub const BlockGroupDescriptor = struct {
    block_usage_bitmap_address: u32,
    inode_usage_bitmap_address: u32,
    inode_table_address: u32,
    unallocated_blocks: u16,
    unallocated_inodes: u16,
    directories: u16,

    pub const binary_size = 32;

    pub fn readFromBinary(bin: []u8) !BlockGroupDescriptor {
        if (bin.len < 18) return error.BufferTooSmall;
        var descriptor: BlockGroupDescriptor = undefined;
        descriptor.block_usage_bitmap_address = std.mem.readIntLittle(u32, bin[0..4]);
        descriptor.inode_usage_bitmap_address = std.mem.readIntLittle(u32, bin[4..8]);
        descriptor.inode_table_address = std.mem.readIntLittle(u32, bin[8..12]);
        descriptor.unallocated_blocks = std.mem.readIntLittle(u16, bin[12..14]);
        descriptor.unallocated_inodes = std.mem.readIntLittle(u16, bin[14..16]);
        descriptor.directories = std.mem.readIntLittle(u16, bin[16..18]);
        return descriptor;
    }

    pub fn getInodeAddress(self: *BlockGroupDescriptor, superblock: *Superblock, inode: u64) u64 {
        return self.inode_table_address * superblock.blockSize() + inode * superblock.inodeSize();
    }
};

pub const Inode = struct {
    pub const Type = enum(u4) {
        fifo = 0x1,
        character_device = 0x2,
        directory = 0x4,
        block_device = 0x6,
        file = 0x8,
        sym_link = 0xA,
        unix_socket = 0xC,
    };

    pub const Permissions = packed struct(u12) {
        other_execute: bool,
        other_write: bool,
        other_read: bool,
        group_execute: bool,
        group_write: bool,
        group_read: bool,
        user_execute: bool,
        user_write: bool,
        user_read: bool,
        sticky_bit: bool,
        set_group_id: bool,
        set_user_id: bool,
    };

    pub const Flags = packed struct(u32) {
        secure_deletion: bool,
        keep_copy_when_deleted: bool,
        file_compression: bool,
        synchronous_updates: bool,
        immutable_file: bool,
        append_only: bool,
        file_not_in_dump: bool,
        dont_update_last_accessed: bool,
        reserved: u8,
        hash_indexed_directory: bool,
        afs_directory: bool,
        journal_file_data: bool,
        end: u13,
    };

    inode_type: Type,
    permissions: Permissions,
    user_id: u16,
    size_lower_32_bits: u32,
    last_access_time: u32,
    creation_time: u32,
    last_modification_time: u32,
    deletion_time: u32,
    group_id: u16,
    count_of_hard_links: u16,
    count_of_disk_sectors: u32,
    flags: Flags,
    os_specific_value_1: u32,
    direct_block_pointers: [12]u32,
    singly_indirect_block_pointer: u32,
    doubly_indirect_block_pointer: u32,
    triply_indirect_block_pointer: u32,
    generation_number: u32,
    extended_attribute_block: u32,
    size_upper_32_bits: u32,
    fragment_block_address: u32,
    os_specific_value_2: u96,

    pub const binary_size = 128;

    pub fn readFromBinary(bin: []u8) !Inode {
        if (bin.len < 128) return error.BufferTooSmall;
        var inode: Inode = undefined;
        var type_and_permissions = std.mem.readIntLittle(u16, bin[0..2]);
        inode.inode_type = @enumFromInt(@as(u4, @intCast(type_and_permissions >> 12)));
        inode.permissions = @bitCast(@as(u12, @intCast(type_and_permissions & 0xFFF)));
        inode.user_id = std.mem.readIntLittle(u16, bin[2..4]);
        inode.size_lower_32_bits = std.mem.readIntLittle(u32, bin[4..8]);
        inode.last_access_time = std.mem.readIntLittle(u32, bin[8..12]);
        inode.creation_time = std.mem.readIntLittle(u32, bin[12..16]);
        inode.last_modification_time = std.mem.readIntLittle(u32, bin[16..20]);
        inode.deletion_time = std.mem.readIntLittle(u32, bin[20..24]);
        inode.group_id = std.mem.readIntLittle(u16, bin[24..26]);
        inode.count_of_hard_links = std.mem.readIntLittle(u16, bin[26..28]);
        inode.count_of_disk_sectors = std.mem.readIntLittle(u32, bin[28..32]);
        inode.flags = @bitCast(std.mem.readIntLittle(u32, bin[32..36]));
        inode.os_specific_value_1 = std.mem.readIntLittle(u32, bin[36..40]);
        for (0..12) |i| {
            inode.direct_block_pointers[i] = std.mem.readIntLittle(u32, @as(*[4]u8, @ptrCast(bin[40 + i * 4 .. 44 + i * 4].ptr)));
        }
        inode.singly_indirect_block_pointer = std.mem.readIntLittle(u32, bin[88..92]);
        inode.doubly_indirect_block_pointer = std.mem.readIntLittle(u32, bin[92..96]);
        inode.triply_indirect_block_pointer = std.mem.readIntLittle(u32, bin[96..100]);
        inode.generation_number = std.mem.readIntLittle(u32, bin[100..104]);
        inode.extended_attribute_block = std.mem.readIntLittle(u32, bin[104..108]);
        inode.size_upper_32_bits = std.mem.readIntLittle(u32, bin[108..112]);
        inode.fragment_block_address = std.mem.readIntLittle(u32, bin[112..116]);
        inode.os_specific_value_2 = std.mem.readIntBig(u96, bin[116..128]);
        return inode;
    }
};

pub const DirectoryEntry = struct {
    pub const Type = enum {
        unknown,
        file,
        directory,
        character_device,
        block_device,
        fifo,
        socket,
        sym_link,
    };

    inode: u32,
    size: u16,
    name_length_lower_8_bits: u8,
    type_or_upper_8_bits: u8,
    name: []u8,

    pub const binary_size = 8;

    pub fn readFromBinary(bin: []u8, superblock: *Superblock) !DirectoryEntry {
        if (bin.len < binary_size) return error.BufferTooSmall;
        var dir: DirectoryEntry = undefined;
        dir.inode = std.mem.readIntLittle(u32, bin[0..4]);
        dir.size = std.mem.readIntLittle(u16, bin[4..6]);
        dir.name_length_lower_8_bits = bin[6];
        dir.type_or_upper_8_bits = bin[7];
        var len: u16 = dir.name_length_lower_8_bits;
        if (superblock.common.major_version < 1) len += @as(u16, dir.type_or_upper_8_bits) << 8;
        dir.name = try EXT2.alloc.alloc(u8, len);
        @memcpy(dir.name, bin[8 .. len + 8]);
        return dir;
    }

    pub fn free(self: *const DirectoryEntry) void {
        EXT2.alloc.free(self.name);
    }
};

pub const Directory = struct {
    entries: std.ArrayList(DirectoryEntry),

    pub fn readFromBinary(bin: []u8, superblock: *Superblock) !Directory {
        var dir: Directory = undefined;
        var pos: u32 = 0;
        dir.entries = std.ArrayList(DirectoryEntry).init(EXT2.alloc);
        while (pos < bin.len) {
            try dir.entries.append(try DirectoryEntry.readFromBinary(bin[pos..], superblock));
            pos += dir.entries.getLast().size;
        }

        return dir;
    }

    pub fn free(self: *Directory) void {
        for (self.entries.items) |entry| {
            entry.free();
        }
        self.entries.deinit();
    }
};

pub const EXT2 = struct {
    superblock: Superblock,
    descriptors: []BlockGroupDescriptor,
    root_directory: Inode,

    var alloc: std.mem.Allocator = undefined;
    var read: *const fn (addr: u64, size: usize, buf: []u8) file.File.ReadError!void = undefined;
    var offset: u64 = 0;

    /// Reads the superblock, block group descriptors, and root directory inode
    pub fn init(allocator: std.mem.Allocator, disk_reader: *const fn (addr: u64, size: usize, buf: []u8) file.File.ReadError!void, disk_offset: ?u64) !EXT2 {
        offset = disk_offset orelse 0;
        alloc = allocator;
        read = disk_reader;
        var ext2: EXT2 = undefined;

        var superblock_buf = try allocator.alloc(u8, Superblock.binary_size);
        try disk_reader(offset + 1024, Superblock.binary_size, superblock_buf);
        ext2.superblock = try Superblock.readFromBinary(superblock_buf);
        allocator.free(superblock_buf);

        const block_groups = try ext2.superblock.blockGroups();
        var block_group_descriptor_buf = try allocator.alloc(u8, block_groups * BlockGroupDescriptor.binary_size);
        try disk_reader(offset + ext2.superblock.blockGroupDescriptorTableStart(), block_groups * BlockGroupDescriptor.binary_size, block_group_descriptor_buf);
        ext2.descriptors = try allocator.alloc(BlockGroupDescriptor, block_groups);
        for (0..block_groups) |group| {
            ext2.descriptors[group] = try BlockGroupDescriptor.readFromBinary(block_group_descriptor_buf[group * 32 .. (group + 1) * 32]);
        }
        allocator.free(block_group_descriptor_buf);

        ext2.root_directory = try ext2.readInode(2);

        return ext2;
    }

    fn readBlock(self: *EXT2, block: u64) file.File.ReadError![]u8 {
        var buf = try alloc.alloc(u8, @intCast(self.superblock.blockSize()));
        try read(offset + self.superblock.blockSize() * block, @intCast(self.superblock.blockSize()), buf);
        return buf;
    }

    fn readInode(self: *EXT2, inode: u64) !Inode {
        const group_index = @divFloor(inode - 1, self.superblock.common.inodes_per_group);
        const index_in_group = (inode - 1) % self.superblock.common.inodes_per_group;
        var buf = try alloc.alloc(u8, self.superblock.inodeSize());
        try read(offset + self.descriptors[@intCast(group_index)].getInodeAddress(&self.superblock, index_in_group), self.superblock.inodeSize(), buf);
        var inode_struct = try Inode.readFromBinary(buf);
        alloc.free(buf);
        return inode_struct;
    }

    pub fn getInodeContents(self: *EXT2, inode: Inode, pos: usize, buf: ?[]u8, to_read: ?u64) file.File.ReadError![]u8 {
        // If file would end before buffer, just read the rest of the file, else read as much as possible into the buffer
        var buffer = if (buf) |b| b else try alloc.alloc(u8, inode.size_lower_32_bits);
        var len_to_read = if (to_read) |t| t else buffer.len;

        const starting_block = pos / self.superblock.blockSize();
        const offset_in_block = pos % self.superblock.blockSize();
        _ = offset_in_block; // TODO: Fix
        for (0..@intCast((len_to_read + self.superblock.blockSize() - 1) / self.superblock.blockSize()), 0..) |block, i| {
            var block_ptr = blk: {
                if (0 <= block + starting_block and block + starting_block < 12) break :blk inode.direct_block_pointers[@intCast(block + starting_block)];
                if (13 <= block + starting_block and block + starting_block < self.superblock.blockSize() / 4 + 13) {
                    const block_data = try self.readBlock(block + starting_block);
                    const block_num = std.mem.readIntLittle(u32, @as(*[4]u8, @ptrCast(block_data.ptr)));
                    alloc.free(block_data);
                    break :blk block_num;
                }
                return error.BufferTooSmall;
            };
            const need_to_read = @min(len_to_read - i * self.superblock.blockSize(), self.superblock.blockSize());
            try read(block_ptr * self.superblock.blockSize() + offset, @intCast(need_to_read), buffer[@intCast(i * self.superblock.blockSize())..]);
        }

        return buffer;
    }

    fn loadDirectory(self: *EXT2, inode: Inode) !Directory {
        // Reads the direct and singly indirect BPs for now, maybe expand later?
        var contents = try self.getInodeContents(inode, 0, null, null);
        var dir = try Directory.readFromBinary(contents, &self.superblock);
        alloc.free(contents);
        return dir;
    }

    fn readFromFile(self: *EXT2, inode: Inode, buf: []u8, pos: usize) file.File.ReadError!usize {
        _ = try self.getInodeContents(inode, pos, buf, buf.len);
        if (pos > inode.size_lower_32_bits) return 0;
        return if (buf.len < inode.size_lower_32_bits) buf.len else inode.size_lower_32_bits;
    }

    pub fn loadFileFromPath(self: *EXT2, path: []u8) !file.File {
        if (path[0] != '/') return error.InvalidPath;
        var cwd = try self.loadDirectory(self.root_directory);
        var split = std.mem.splitScalar(u8, path[1..], '/');
        var file_inode: Inode = while (split.next()) |dir| {
            var entry = for (cwd.entries.items) |item| {
                if (std.mem.eql(u8, item.name, dir)) break item;
            } else return error.InvalidPath;
            var entry_inode = try self.readInode(entry.inode);
            if (entry_inode.inode_type == .directory) {
                cwd.free();
                cwd = try self.loadDirectory(entry_inode);
            } else if (entry_inode.inode_type == .file) {
                cwd.free();
                break entry_inode;
            }
        };
        var inode_copy = try alloc.create(Inode);
        var extra_context = try alloc.create(ExtraFileContext);
        extra_context.* = ExtraFileContext{
            .inode = inode_copy,
            .fs = self,
        };
        inode_copy.* = file_inode;
        var f: file.File = .{
            .pos = 0,
            .read_fn = struct {
                pub fn read(ctx: *file.File, dest: []u8) file.File.ReadError!usize {
                    var extra: *ExtraFileContext = @alignCast(@ptrCast(ctx.extra));
                    const val = try extra.fs.readFromFile(extra.inode.*, dest, ctx.pos);
                    ctx.pos += dest.len;
                    return val;
                }
            }.read,

            .free_fn = struct {
                pub fn free(ctx: *file.File) !void {
                    var extra: *ExtraFileContext = @alignCast(@ptrCast(ctx.extra));
                    alloc.destroy(extra.inode);
                    alloc.destroy(extra);
                }
            }.free,

            .get_size_fn = struct {
                pub fn getSize(ctx: *file.File) !usize {
                    var extra: *ExtraFileContext = @alignCast(@ptrCast(ctx.extra));
                    return extra.inode.size_lower_32_bits;
                }
            }.getSize,

            .extra = extra_context,
        };
        return f;
    }

    pub fn free(self: *EXT2) void {
        alloc.free(self.descriptors);
    }
};

pub const ExtraFileContext = struct {
    inode: *Inode,
    fs: *EXT2,
};
