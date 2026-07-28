From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 27 Jul 2026 19:07:19 -0500
Subject: [PATCH] dm array: validate array block headers on read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-b4-disp-0d625fe8-v1-1-be31f8611720@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrmlSGwTiVQiL6UzRukAyBWJCu
 LujLt/i/wNcs6nDrTog625ur7ngUlcQH2G+K1oqBiZuqeMOpcFkviCllq+T9kh9JG5EKEqAki1
 ZJ3v/lsP4t2/y1Lh+P3CeHw5yt1t0AAAA
X-Change-ID: 20260727-b4-disp-0d625fe8-08c024bb0cba
To: Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>
Cc: linux-kernel@vger.kernel.org, Joe Thornber <ejt@redhat.com>, 
 Alasdair Kergon <agk@redhat.com>, Ming-Hung Tsai <mtsai@redhat.com>, 
 Benjamin Marzinski <bmarzins@redhat.com>, dm-devel@lists.linux.dev
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785197238; l=5869;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=cupIkXaOfmmZcfnSmxZVIgmIPgt7jYhcjoeV+LtA/gk=;
 b=ubGfyAkJVWCzYNzuMNuMHcYggYfF8Aehdtl8bChkEPbXmhuhCwTupyI9MCS2KiUTphHBZH7xA
 fYeJnTafP/PBMgxUQpY3BuLpcti20tgeC8aFVUNKTzfQUjV66V4sJfM
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

array_block_check() validates an array block's blocknr and checksum and
nothing else, so the on-disk nr_entries reaches its users unchecked.
dm_array_cursor_next() takes its loop bound from that field and
element_at() is unguarded pointer arithmetic, so a value larger than the
block holds walks off the end of the dm-bufio buffer, reachable from
dm_cache_load_mappings() when a cache is activated on crafted metadata.

Validate the header as node_check() has always validated btree nodes:
reject a block whose entries cannot fit, and one whose nr_entries exceeds
max_entries.  Metadata that dm-array wrote itself sits exactly at that
limit and still passes.

Fixes: 6513c29f44f2 ("dm persistent data: add transactional array")
Cc: stable@kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Found by reading array_block_check() next to node_check(), its opposite number for btree
nodes in the same directory.  node_check() already bounded max_entries and nr_entries when
dm-array was added in 2013; the array validator never picked it up.

Reproducer.  Create a cache on a zeroed metadata device so dm-cache formats it, tear that
down, then set nr_entries in the first mapping array block to 0xFFFFFFFF and recompute the
block checksum.  dm_bm_checksum() is crc32c(~0, data, len) ^ CSUM_XOR, so the checksum costs
nothing to forge -- it is a corruption check, not a tag.  The crafted image differs from the
one the kernel itself wrote by four bytes plus that checksum.

A 4096-byte block with a 24-byte header and 8-byte values holds 509 entries, so index 509 is
the first one outside it.

A/B on v7.2-rc4-610 with KASAN and kasan.fault=report, this patch built as posted:

  pristine image, unpatched:  activates, walks all 2048 cache blocks, dmesg empty
  crafted image,  unpatched:  reads past the block, below
  crafted image,  patched:    "array_block_check failed: too many entries", -EILSEQ
  pristine image, patched:    activates, dmesg empty

    BUG: KASAN: slab-use-after-free in dm_cache_load_mappings+0x9b1/0xb40 [dm_cache]
    Read of size 8 at addr ffff888107fc8000 by task dmsetup/1667
     dm_cache_load_mappings+0x9b1/0xb40 [dm_cache]
     cache_preresume+0x4cd/0xd70 [dm_cache]
     dm_table_resume_targets+0xcd/0x2e0 [dm_mod]
     ctl_ioctl+0x512/0xa90 [dm_mod]
     __x64_sys_ioctl+0x134/0x1c0
    The buggy address is located 0 bytes inside of
     freed 32-byte region [ffff888107fc8000, ffff888107fc8020)

The block base was ffff888107fc7000, so that address is base + 0x1000: byte 4096, index 509,
the first entry outside.

Worth flagging about that KASAN line: it corroborates, it does not reproduce on demand.  Two
earlier runs of the same arm produced no report at all, even though the overread happened
both times and dm-cache said so by refusing a nonsense mapping at cache block 509.  dm-bufio
serves this buffer from __get_free_pages(), the page allocator has no redzones, and byte 4096
is the first byte of the next page, so KASAN can only speak when that page happens to be
poisoned.  The first line is the deterministic one.

The check is not conservative.  calc_max_entries() gives 509 for 8-byte values and 1018 for
4-byte ones, and 24 + 8*509 and 24 + 4*1018 are both exactly 4096, so metadata dm-array wrote
sits right at the limit and still passes.

There is a second hole I am not fixing here, since it wants its own reproducer and this one is
headed for stable.  A validator can only check a header against itself, so a block with
value_size 4 and max_entries 1018 is internally consistent and gets through, but element_at()
indexes with the caller's value size rather than the stored one -- and dm-cache keeps arrays of
both, mappings at 8 and hints at 4.  Read an array block of one through the other and the walk
runs to byte 8160 of a 4096-byte block.  Closing that means comparing value_size against
info->value_type.size in get_ablock() and in __shadow_ablock(), the two places that hold both
the block and the caller.

dm-era reaches the same accessor directly and dm-clone reaches it through dm-bitset, which is
an array underneath; dm-cache is only the shortest path from a crafted image to an observable
read.  All of them need CAP_SYS_ADMIN to load the table, which is why I'm sending this as
hardening rather than as a security report.

The value_size patch follows once I have a reproducer for it.
---
 drivers/md/persistent-data/dm-array.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/md/persistent-data/dm-array.c b/drivers/md/persistent-data/dm-array.c
index 8f8792e55806..03d4ffdb3521 100644
--- a/drivers/md/persistent-data/dm-array.c
+++ b/drivers/md/persistent-data/dm-array.c
@@ -55,6 +55,7 @@ static int array_block_check(const struct dm_block_validator *v,
 			     size_t size_of_block)
 {
 	struct array_block *bh_le = dm_block_data(b);
+	uint32_t nr_entries, max_entries, value_size;
 	__le32 csum_disk;
 
 	if (dm_block_location(b) != le64_to_cpu(bh_le->blocknr)) {
@@ -74,6 +75,22 @@ static int array_block_check(const struct dm_block_validator *v,
 		return -EILSEQ;
 	}
 
+	nr_entries = le32_to_cpu(bh_le->nr_entries);
+	max_entries = le32_to_cpu(bh_le->max_entries);
+	value_size = le32_to_cpu(bh_le->value_size);
+
+	if (!value_size ||
+	    sizeof(struct array_block) +
+	    (uint64_t) value_size * max_entries > size_of_block) {
+		DMERR_LIMIT("%s failed: max_entries too large", __func__);
+		return -EILSEQ;
+	}
+
+	if (nr_entries > max_entries) {
+		DMERR_LIMIT("%s failed: too many entries", __func__);
+		return -EILSEQ;
+	}
+
 	return 0;
 }
 

---
base-commit: 4235cb24ec1e8e96843f3671ba4da2a6ccca2c7b
change-id: 20260727-b4-disp-0d625fe8-08c024bb0cba

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

