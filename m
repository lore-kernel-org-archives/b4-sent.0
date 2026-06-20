From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 20 Jun 2026 16:41:31 -0500
Subject: [PATCH] nvdimm/btt: reject an arena whose nfree is below the lane
 count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260620-b4-disp-88b2514b-v1-1-3834e707d232@proton.me>
X-B4-Tracking: v=1; b=H4sIAAoJN2oC/x3MQQqAIBBA0avErBsYxcq6SrTQmmo2FgoRiHdPW
 r7F/xkSR+EEU5Mh8iNJrlCh2gbW04WDUbZq0KR76jWhN7hJutFarztlPK6DYuvIu2EkqNkdeZf
 3X85LKR/o3DTmYgAAAA==
To: Dave Jiang <dave.jiang@intel.com>, Ira Weiny <ira.weiny@intel.com>, 
 Vishal Verma <vishal.l.verma@intel.com>, Dan Williams <djbw@kernel.org>
Cc: linux-kernel@vger.kernel.org, nvdimm@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781991690; l=2686;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=SRVc7PL0/UeJ4JAXyVEbfu4zyngcHm0zDEpZdxTj7Zg=;
 b=hI3LF2j8X5V6E7w7MIwo9J1GEp2W1PcpiPEvTvhGhFuuiF6Tb1S5I3qH7me12B2G1V+lnF6AU
 6/hccA7sC+5AZwY//v/eYHKlPQQy7yx+j6QU4LvpTbMhhjUVS/MNMFw
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The BTT info block's nfree field, the number of reserve free blocks, is
read from the medium without validation.  btt_freelist_init() and
btt_rtt_init() size the per-lane freelist[] and rtt[] arrays by nfree,
but the I/O path indexes them by the lane from nd_region_acquire_lane(),
which is bounded by nd_region->num_lanes (ND_MAX_LANES), not by nfree.
A crafted or foreign arena whose nfree is below the lane count makes
freelist[lane]/rtt[lane] run past the allocation: an out-of-bounds write.

btt.rst documents the nlanes = min(nfree, num_cpus) invariant, which the
code does not currently honor: num_lanes is ND_MAX_LANES regardless of
nfree.  Reject an arena whose nfree is below num_lanes at discovery,
before the per-lane arrays are allocated, enforcing that invariant.

Fixes: 5212e11fde4d ("nd_btt: atomic sector updates")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
nd_btt_arena_is_valid() checks the signature, parent_uuid and a fletcher
checksum, none of which constrain nfree; the checksum is keyless, so a
crafted arena recomputes it.  map_locks[] is indexed modulo nfree and is
unaffected; only the lane-indexed freelist[] and rtt[] are out of bounds.

Reproduced with an out-of-tree module that mirrors btt_rtt_init() ->
btt_read_pg() (kcalloc(nfree) then rtt[lane] across the lane range), since
the defect is the unchecked nfree vs the lane bound:

Build A (without this patch), nfree=2, num_lanes=8:
    rtt[lane] for lane >= nfree writes past the kcalloc'd array ->
      right of the 8-byte region (kmalloc-8) -> panic.
  Build B (with this patch): the arena is rejected, no array is used -> clean.
  Control (nfree >= num_lanes): every lane is in bounds -> clean.

BUG: KASAN: slab-out-of-bounds, Write of size 4, 0 bytes to the
---
 drivers/nvdimm/btt.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/nvdimm/btt.c b/drivers/nvdimm/btt.c
index fdcb080a4314..25c609251f99 100644
--- a/drivers/nvdimm/btt.c
+++ b/drivers/nvdimm/btt.c
@@ -883,6 +883,14 @@ static int discover_arenas(struct btt *btt)
 		arena->external_lba_start = cur_nlba;
 		parse_arena_meta(arena, super, cur_off);
 
+		if (arena->nfree < btt->nd_region->num_lanes) {
+			dev_err(to_dev(arena),
+				"nfree %u smaller than lane count %d\n",
+				arena->nfree, btt->nd_region->num_lanes);
+			ret = -ENODEV;
+			goto out;
+		}
+
 		ret = log_set_indices(arena);
 		if (ret) {
 			dev_err(to_dev(arena),

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260620-b4-disp-88b2514b-c71e8a0ba790

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

