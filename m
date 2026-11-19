From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Thu, 19 Nov 2026 20:33:21 +0200
Subject: [PATCH] EDAC/ie31200: Give each DIMM two chip selects again
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-edac-ie31200-rank-stride-v1-1-3514fcccb130@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtoulnQVxEPXRM1ClWSTYSxd
 1/V43f4/wVcTMXh2C1g8lbXZ22gXQfllutVULkZYoiJiA4onAuq9BRDQMv1gT6ZsmDmsadBEqd
 9gpa/TC76+a1P5799Hu9Spu8P1nUDX+oDgHwAAAA=
X-Change-ID: 20261119-edac-ie31200-rank-stride-adb314e6d656
To: Jason Baron <jbaron@akamai.com>, Borislav Petkov <bp@alien8.de>, 
 Tony Luck <tony.luck@intel.com>, Qiuxu Zhuo <qiuxu.zhuo@intel.com>
Cc: linux-edac@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795113201; l=3793;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=VP8SCFbiML+yq2OXuS5I12VRNITneI1RQB16ykCjEfc=;
 b=S+ImWECOBViK7xaKc+IUCgF2y4TrPCmCl9t23ueND5tdDMfApnbzaC+WxUEvF92lL+Jnrhntb
 70pqRNLn8GmBJdDSQM3J1yQ1VaV6Rg1/NciQCDDGMQKx/ctMh+pHEk7
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit afdbc3655556 ("EDAC/ie31200: Make struct dimm_data
contain decoded information"), ie31200_get_dimm_config() puts rank k
of DIMM j at chip select j * ranks + k, where ranks is that DIMM's own
rank count. In a channel with a dual-rank DIMM 0 and a single-rank
DIMM 1, both DIMMs then use chip select 1: DIMM 1 overwrites the entry
for DIMM 0's second rank, mc0/size_mb is short by that rank, and errors
in it are reported against DIMM 1.

Before that commit the stride was a fixed 2, so DIMM 0 had chip
selects 0-1 and DIMM 1 had 2-3, and the commit did not mean to change
that. The error path still passes the two-bit rank field of ECCERRLOG
to edac_mc_handle_error() as the chip select. If the controller reports
DIMM 1's first rank as 2, as the old layout assumed, those errors now
land on an empty entry when DIMM 1 is single-rank (or when both DIMMs
are, as DIMM 1 has moved to chip select 1). That trips
WARN_ON_ONCE(!e->grain) in edac_raw_mc_handle_error() and the error is
logged against "unknown memory".

Go back to a fixed stride of 2.

Fixes: afdbc3655556 ("EDAC/ie31200: Make struct dimm_data contain decoded information")
Cc: stable@vger.kernel.org
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
I ran into this with a QEMU model of the Kaby Lake host bridge (0x5918,
skl_cfg) that I wrote to exercise ie31200_edac; it is not part of
upstream QEMU. It fills MAD_DIMM in from the configured DIMMs and
reports errors on DIMM S (the driver's DIMM 1) with ECCERRLOG rank 2 or
3, which is the layout the driver used up to v6.14. I have no machine
with two DIMMs per channel to check what real controllers put in that
field, so the "unknown memory" part rests on the old layout. The size_mb
part only depends on MAD_DIMM.

Tested on v7.4-rc3+ (4405c18c95d2) with both slots of both channels
populated, injecting corrected errors on DIMM L's ranks and on DIMM S in
both channels, and an uncorrected error on DIMM S:

  ranks L + S  without the patch                 with it
  2R + 1R      mc0/size_mb 3072 instead of 4096; mc0/size_mb 4096;
               DIMM S errors on "unknown         DIMM S errors on
               memory", WARN in edac_mc.c        csrow 2
  1R + 1R      mc0/size_mb 4096; DIMM S errors   mc0/size_mb 4096;
               on "unknown memory", WARN         DIMM S errors on
                                                 csrow 2
  2R + 2R      correct                           unchanged

On RPL-S, MAD_DIMM can describe up to four ranks per DIMM, so this also
moves DIMM 1 there: a 1R + 1R channel goes from chip selects 0 and 1 to
0 and 2. ECCERRLOG has the same two-bit rank field on RPL-S, so I think
two chip selects per DIMM is still the right split, but I could not
test it. Qiuxu, do you know how the RPL-S controller numbers the ranks
of the second DIMM in ECCERRLOG?
---
 drivers/edac/ie31200_edac.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/edac/ie31200_edac.c b/drivers/edac/ie31200_edac.c
index 88af77ee07fe..1ef91cbda291 100644
--- a/drivers/edac/ie31200_edac.c
+++ b/drivers/edac/ie31200_edac.c
@@ -461,7 +461,7 @@ static void ie31200_get_dimm_config(struct mem_ctl_info *mci, void __iomem *wind
 
 			nr_pages = nr_pages / dimm_info.ranks;
 			for (k = 0; k < dimm_info.ranks; k++) {
-				dimm = edac_get_dimm(mci, (j * dimm_info.ranks) + k, i, 0);
+				dimm = edac_get_dimm(mci, (j * 2) + k, i, 0);
 				dimm->nr_pages = nr_pages;
 				edac_dbg(0, "set nr pages: 0x%lx\n", nr_pages);
 				dimm->grain = 8; /* just a guess */

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261119-edac-ie31200-rank-stride-adb314e6d656

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

