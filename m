From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH v2 0/2] dm array: validate array block headers, and against
 the caller
Date: Fri, 31 Jul 2026 17:54:53 -0500
Message-Id: <20260731-b4-disp-4fd3bed9-v2-0-7b1835e4e7f6@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzMDc2ND3SQT3ZTM4gJdk7QU46TUFEtdYwvzZOO0VCBpYqQE1FZQlJqWWQE
 2MjoWwi8uTcpKTS4BmaNUWwsA9nuJUnQAAAA=
X-Change-ID: 20260731-b4-disp-4fd3bed9-387c3fe87c42
To: Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>
Cc: Ming-Hung Tsai <mtsai@redhat.com>, 
 Benjamin Marzinski <bmarzins@redhat.com>, dm-devel@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Alasdair Kergon <agk@redhat.com>, 
 Joe Thornber <ejt@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785538493; l=5489;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=3szjRRUOnQWAmqw62BCFpRphKGY+rm6LLuIDNM7/6Pg=;
 b=qYgRhwTPKzpkpDwvwFv73L/Ak43L6PePAY9nxbV8z+FLKXYScp8QHERA18yOT79H7rwq6ySj4
 d+emCVLxZh/B7Mh5PDONNOTLSqkpYWcHt17OT4ya/BylXmQQ+CaKW0F
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1 fixed one of these and mentioned the other; this is both, and the second one
is here because Ming-Hung Tsai said how to reproduce it.

An array block header can be wrong in two independent ways, and a validator can
only catch the first. 1/2 makes the header consistent with itself: value_size
non-zero, max_entries exactly calc_max_entries() for that value_size and block
size, nr_entries within it. 2/2 catches the header that is perfectly consistent
with itself and still wrong for the array reading it.

The review of v1 [1] asked for three changes to the first, all taken: compare
max_entries for equality rather than bounding it from above, since a count
BELOW the real capacity reaches BUG_ON(new_nr > ab->max_entries) in
fill_ablock() and trim_ablock(); split the !value_size test out with its own
message; and print
the counts rather than a bare "max_entries too large". calc_max_entries() moved
above the validators so it is in scope there -- it is unchanged, and
open-coding the formula was what I wanted to avoid, since max_entries is what
dm_array_get_value() addresses with.

2/2 is the hole v1 described and did not fix. dm-cache keeps two arrays,
mappings at 8 bytes and hints at 4, and both roots sit in the superblock. A
hint block stores value_size 4 and max_entries 1018, and 24 + 4*1018 is exactly
4096, so it is internally consistent and 1/2 passes it -- the validator sees the
block, never the caller. Swap the two roots and __load_mappings() walks the hint
array through an info whose value size is 8. get_ablock() and __shadow_ablock()
are the two readers that hold the block and the caller at once, which is why the
check has to be in both; covering only one is why this was not in v1.

A/B on v7.2-rc1 with KASAN; dm-array.c, dm-bufio.c and dm-cache-metadata.c are
identical between that and the base of this series. dm-persistent-data is a
module here, so an arm is the .ko that is loaded and the tested code carries no
scaffolding. Every image is derived from metadata dm-cache itself wrote:

  pristine,                  unpatched:  activates, loads its mappings
  nr_entries 0xFFFFFFFF,     unpatched:  reads past the block, below
  max_entries 100,           unpatched:  ACTIVATES CLEAN -- accepted today
  roots swapped,             unpatched:  reads past the block, below
  nr_entries 0xFFFFFFFF,     patched:    "too many entries", -EILSEQ
  max_entries 100,           patched:    "max_entries 100 != wanted 509 for value_size 8"
  roots swapped,             patched:    "get_ablock failed: value_size 4 != wanted 8"
  pristine,                  patched:    activates, dmesg empty

Three crafted images, three different rejections, and the real image still
loads. The two overread arms, with the consequence dm-cache reports on its own:

    device-mapper: cache: 252:0: unable to shrink origin; cache block 509 is dirty
    device-mapper: cache metadata: policy couldn't load cache block 509     (nr_entries)

    device-mapper: cache: 252:0: unable to shrink origin; cache block 911 is dirty
    device-mapper: cache metadata: policy couldn't load cache block 911     (roots swapped)

509 is exactly the first index an 8-byte-value block cannot hold. 911 is only
where the swapped-root walk first decodes a mapping dm-cache refuses; it depends
on the data, not on a boundary.

Those two lines are the oracle. KASAN adds little here. One run of the
nr_entries arm reported

    BUG: KASAN: slab-use-after-free in dm_cache_load_mappings+0x9b1/0xb40 [dm_cache]

but that build carried an extra warning I had put at the read site to locate it,
and no run since has reported anything. dm-bufio serves these buffers from
__get_free_pages(), the page allocator has no redzones, and the first byte past
the block is the first byte of the next page, so KASAN only speaks when that
page happens to be poisoned.

Scope of the max_entries arm, since it is weaker than the other two: it shows
the header is accepted today and rejected with 1/2, which is what the equality
is for. It does not show the BUG_ON firing -- reads bound themselves by
nr_entries, so a too-small max_entries only bites on a later resize, and I did
not drive one. By inspection from fill_ablock() and trim_ablock().

Forging any of this costs nothing: dm_bm_checksum() is crc32c(~0, data, len) ^
xor, a corruption check rather than a tag. Each crafted image differs from the
one the kernel wrote by four or sixteen bytes plus a checksum.

All of it needs CAP_SYS_ADMIN to load the table, which is why this is hardening
rather than a security report. dm-era reaches the same accessor directly and
dm-clone reaches it through dm-bitset; dm-cache is only the shortest path from a
crafted image to an observable read. dm-thin uses neither. cache_check and
era_check have caught the value_size case offline since v1.0; this is the online
half.

[1] https://lore.kernel.org/all/CALjSBEt-PGxY7y6tQYx6iCmFRXqVcwr633FoFsE+L13A=gre4Q@mail.gmail.com/

---
Bryam Vargas (2):
      dm array: validate array block headers on read
      dm array: reject an array block whose value size is not the caller's

 drivers/md/persistent-data/dm-array.c | 54 +++++++++++++++++++++++++++++------
 1 file changed, 46 insertions(+), 8 deletions(-)
---
base-commit: 8ba098e6b6ff0db8edf28528d1552be261af30d4
change-id: 20260731-b4-disp-4fd3bed9-387c3fe87c42

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

