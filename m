From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH 0/2] dm btree: bound a node header, and check it against
 the reading level
Date: Fri, 31 Jul 2026 21:32:02 -0500
Message-Id: <20260731-b4-disp-1fdddbbb-v1-0-4879ae1012a2@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz7WUBEppr4IYMDatGSiKASEh7
 k5oxzf8v4NJVDF4ZTtEWdX0Oyb4Wwbdpx3fgsrJEFwo3SP3SAWy2oS+Z2YiwmfOVFTsKJR3SNk
 Updftt6ybv22hQbr5+sBxnJ76Lcp0AAAA
X-Change-ID: 20260731-b4-disp-1fdddbbb-93db48d0b265
To: Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>
Cc: Joe Thornber <ejt@redhat.com>, Ming-Hung Tsai <mtsai@redhat.com>, 
 Heinz Mauelshagen <heinzm@redhat.com>, Alasdair Kergon <agk@redhat.com>, 
 dm-devel@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Benjamin Marzinski <bmarzins@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785551523; l=6394;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=yKn5YverXKRVJM4kUkJ1vD2X43xAN3M+1rIG00GC2Ec=;
 b=y79n7u9YeXlsihOZdrs7N2MpDv7mpK38R0OiSwcLIuoODgy1/S4Kct5CbTC9lIEoMDu5tCWBT
 o0r6eQDU7zOAwhO57lyx0P170V3/1QyfjxJUO/uqeH5aZw43GHg6DZX
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A node header can be wrong in two independent ways and a validator only
reaches the first, so this is two patches. 1/2 holds the header to the
geometry every writer produces. 2/2 catches the header that is internally
perfect and still wrong for the level reading it.

value_ptr() places an entry from the value_size stored on disk while the
caller supplies the length it copies. node_check() weighs the header against
itself and nothing else, so it never rejects value_size 0, never requires
max_entries to equal calc_max_entries(), and never sees the caller.

With value_size 0 the stride collapses and max_entries alone places
value_base(). At 508 that is 32 + 8*508, exactly 4096, and the reject is a
strict >, so the block is accepted with its value area starting on the first
byte of the next page. 1/2 rejects that and two siblings of it: an internal
node whose value_size is not sizeof(__le64), which btree_split_beneath()
never writes and value64() already assumes, and a max_entries that disagrees
with calc_max_entries(), the formula every writer computes it from.

That is as far as a validator reaches, and it is not far enough. A details
node written value_size 1 gets max_entries 450 from the same formula, so it
satisfies 1/2 completely, and dm-thin then reads it through an info whose
value size is 24. That is 2/2.

Where 2/2 puts the check is the part I would most like reviewed. Everything
that modifies a node reaches it through bn_shadow(), which is already handed
the level's value type, so one check there covers insert, both splits,
remove, remove_leaves and the space map's refcount overflow leaf. That
includes insert_at(), which strides with the caller's size over a base
placed by the node's own and is the widest write here: on a details tree
laid out for value_size 1, inserting at index 0 moves nr_entries * 24 bytes
from 3632 bytes into a 4096 byte block. The readers share no chokepoint that
knows the expected size, so they take the check individually -- the lookup
and cursor readers, the walk callback, and dm_btree_del(), which walks on
its own frame stack. shadow_child(), init_child() and rebalance_children()
take it as well, the last because it copies a child over a node the spine
has already cleared.

A/B on v7.2-rc1 with KASAN. drivers/md/persistent-data/ is identical between
that and the base of this series; dm-bufio.c and dm-thin-metadata.c have each
taken one fix since, in dm_bufio_issue_discard() and the metadata-snapshot
path, neither of which these arms reach. dm-persistent-data is a module here,
so an arm is the .ko that is loaded and the tested code carries no
scaffolding. Both images derive from metadata a thin-pool itself wrote; the
crafted one differs in three header fields, 450 keys and the recomputed
checksum.

                        unpatched      1/2 only        1/2 + 2/2
  pristine              activates      activates       activates
  crafted, key 400      accepted       accepted        rejected
  crafted, key 449      accepted       accepted        rejected

"accepted" is the finding. With 1/2 alone the crafted node passes node_check
without a word and dm_btree_lookup() reads past the block:

    BUG: KASAN: slab-use-after-free in btree_lookup_raw+0x21e/0x360
    Read of size 24 at addr ffff88810a3b1ff1 by task dmsetup/3016
      __asan_memcpy
      btree_lookup_raw
      dm_btree_lookup
      __open_device [dm_thin_pool]
      dm_pool_open_thin_device
      thin_ctr

0xff1 is 4081 from the start of the block: value_base 3632 plus the last of
450 entries. 4081 + 24 is 4105, so nine of those bytes are the next page,
which on that run began a slab whose first object was free. With both patches
the same image is refused at check_value_size, thin_ctr returns -EILSEQ, and
the pristine image still activates under all three builds.

The unpatched arm accepts and reads identically but did not report, and that
asymmetry is the rig rather than the code: the nine bytes land wherever the
next page happens to be, and KASAN only speaks if that is a redzone or a freed
object. Whether it reports is a property of the neighbour, not of the bug.

The key-400 arm is not an overread: its entry resolves fully inside the
block. It is there to show where the bytes go. I planted a mapped_blocks of
0xABCD at that offset and dmsetup status reported 5629568, which is 0xABCD
times the 128 sector block size. Whatever value_ptr() lands on becomes
device details, and mapped_blocks is printed, so the read reaches userspace.

Forging costs nothing: dm_bm_checksum() is crc32c(~0, data, len) ^ xor, a
corruption check rather than a tag.

All of it needs CAP_SYS_ADMIN to load the table, which is why this is
hardening rather than a security report. dm-thin is the shortest path from a
crafted image to an observable read because its two value sizes differ by
enough to matter; 24 is the widest in tree, and with 15 or fewer the last
entry still lands inside the block. dm-cache, dm-era and dm-clone reach
value_ptr() through the same entry points.

Two things the arms do not cover. 1/2's internal-node rule follows from
btree_split_beneath() writing sizeof(__le64) into every internal node and
from value64() indexing with 8 regardless; that is by inspection, not
reproduced. And the arms drive the read path only. The write sites are argued
from the same arithmetic and compile tested, not separately reproduced: an
attempt to witness the insert path did not produce a report, because dm-bufio
serves the block from __get_free_pages() and a write past it corrupts the next
page rather than tripping a redzone, so it surfaces later and elsewhere.

---
Bryam Vargas (2):
      dm btree: hold a node header to the geometry its writers guarantee
      dm btree: reject a node whose value size is not the reading level's

 drivers/md/persistent-data/dm-btree-internal.h |  8 ++-
 drivers/md/persistent-data/dm-btree-remove.c   | 24 ++++++--
 drivers/md/persistent-data/dm-btree-spine.c    | 33 ++++++++++-
 drivers/md/persistent-data/dm-btree.c          | 81 +++++++++++++++++++++++---
 4 files changed, 130 insertions(+), 16 deletions(-)
---
base-commit: 8ba098e6b6ff0db8edf28528d1552be261af30d4
change-id: 20260731-b4-disp-1fdddbbb-93db48d0b265

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

