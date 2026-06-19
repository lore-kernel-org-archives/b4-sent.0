From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH 0/3] dm-pcache: validate on-disk fields before use
Date: Fri, 19 Jun 2026 06:44:54 -0500
Message-Id: <20260619-b4-disp-997773a1-v1-0-14df8aedb323@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALYrNWoC/x3MQQqAIBBA0avErBvQDMWuEi2mnGo2FgoRiHdPW
 r7F/wUyJ+EMU1cg8SNZrtig+w62k+LBKKEZBjVYZbXHdcQg+UbvnXOGNFpPgbQKhgxDy+7Eu7z
 /cl5q/QAFVmH0YgAAAA==
To: Dongsheng Yang <dongsheng.yang@linux.dev>, Zheng Gu <cengku@gmail.com>
Cc: linux-kernel@vger.kernel.org, Mikulas Patocka <mpatocka@redhat.com>, 
 dm-devel@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781869494; l=2680;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=AuAvjSYW6ETSoS2LpoKglEo3RierbpsTzWflE2fvQ5s=;
 b=Wy+rmqffze5Fioo3hwyx8CmXsMYrS9U0prLQqoerFad1jcUVDtbWRpD4a2g35fntG5KYYjxbH
 T8kmColW9+VBcLGJeYqp5GgtEgfzzvGur0UcjqTzp1i+TgX23E5+BFt
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dm-pcache reads its layout from the cache device and mostly trusts it. The
table load needs CAP_SYS_ADMIN, but the on-media metadata is only self-checked
with a CRC32C over a fixed, public seed, so anyone who can format or swap the
cache device forges the fields and recomputes the CRC. Several of them become
segment ids, array indices, loop counts and intra-segment extents with no bound
against the device geometry, which turns crafted metadata into kernel
out-of-bounds accesses, both at table load and during normal cache I/O.

Each patch adds the bound where the field is decoded:

  1/3  segment ids that index cache->segments[] -- bound against cache->n_segs
       (cache_pos_decode, cache_key_decode, and the last-kset paths in replay,
       writeback and gc).
  2/3  cache_info->n_segs and the segment-chain ids -- bound against the cache
       device segment count.
  3/3  the kset key_num, read by cache_kset_crc() and the replay loop before the
       CRC is even compared, and a key whose offset+length runs past its segment
       -- the latter is an OOB read that otherwise reaches user space on a cache
       read hit.

I found these by walking the cache-device decode paths. Each class reproduces in a
faithful in-kernel model under KASAN: the bug arm faults (slab out-of-bounds -- a
read for the seg_id, geometry and key_num/extent cases, a write for the n_segs
loop), the arm with the added bound is clean, and valid metadata is clean. The key
offset/length case also reproduces under KMSAN, where the over-read returns
uninitialized kernel memory. Reproducer available on request. Each check rejects
bad metadata with -EIO and leaves valid metadata alone.

checkpatch --strict is clean apart from "Alignment should match open
parenthesis" on the multi-line pcache_dev_err() calls, which match the style
already in the driver.

---
Bryam Vargas (3):
      dm-pcache: validate seg_id fields from persistent memory
      dm-pcache: validate geometry fields from on-disk cache_info
      dm-pcache: validate kset key_num and intra-segment bounds

 drivers/md/dm-pcache/cache.c           | 17 +++++++++++++++++
 drivers/md/dm-pcache/cache.h           | 35 ++++++++++++++++++++++++++++++++++
 drivers/md/dm-pcache/cache_gc.c        | 24 +++++++++++++++++------
 drivers/md/dm-pcache/cache_key.c       | 21 +++++++++++++++++++-
 drivers/md/dm-pcache/cache_writeback.c | 22 ++++++++++++++-------
 5 files changed, 105 insertions(+), 14 deletions(-)
---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260619-b4-disp-997773a1-69ada10d3a3e

Best regards,
-- 
bryamzxz <hexlabsecurity@proton.me>

