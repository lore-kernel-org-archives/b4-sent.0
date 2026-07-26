From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sun, 26 Jul 2026 18:29:11 -0500
Subject: [PATCH] ntfs: bound the free-cluster bitmap scan to the volume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260726-b4-disp-9cd2a8a2-v1-1-8d66c6dceac4@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrm1Si2HAqxgXQ6dAWSCZqiEh3
 N1Rl2/x/w6u2dThWu2Q9W1uj6XgfKpApriMipaKgYkbCtxgf8FkvmIniWMbGYmC1LELJG2Akq1
 ZB9t+y9v9b3/1s8rz+4Hj+ABpWIhddAAAAA==
X-Change-ID: 20260726-b4-disp-9cd2a8a2-007c3a970c87
To: Hyunchul Lee <hyc.lee@gmail.com>, Namjae Jeon <linkinjeon@kernel.org>
Cc: linux-kernel@vger.kernel.org, ntfs@lists.linux.dev, 
 linux-fsdevel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785108550; l=5276;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=akZR/VIonRIQ3VM50tM3Lj+DRslt6FDmCufqoCFdNnE=;
 b=mb+EJlER+r0cIciA7O/tFLKu+2XUNCT8fER4YKOqaUTcC/O4PAvqt9xRW57fTbm5Ik/M6s49O
 XDnpOxMFXXLDYJiYELvXQoAyocKc/767gLmbWK7dLC+sOQdO1uLE0Jx
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vol->lcn_empty_bits_per_page is sized from vol->nr_clusters at mount, but
ntfs_cluster_alloc() bounds its scan of that array by the size of $Bitmap.
Those are independent on-disk quantities and the mount-time check only
rejects a $Bitmap that is too small, so an image whose $Bitmap covers more
clusters than the volume has lets the scan index past the array.  A run
whose LCN lies in that gap takes the allocator straight there, since the
caller passes the file's own last LCN as its locality hint.  KASAN reports
a slab out-of-bounds read when a file on such a volume is extended.

Clamp the scan to what that array covers, mirroring the max_index
calculation the mount-time scan already uses, and reject a decoded LCN
at or beyond nr_clusters in the mapping pairs decoder.  Conforming
volumes are unaffected.

Fixes: 11ccc9107dc4 ("ntfs: update runlist handling and cluster allocator")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Either hunk alone stops the access; they close it at different levels.  The
clamp bounds the index whatever the caller passes as a hint.  The decoder
check stops a run pointing outside the volume from being accepted at all,
which also covers ntfs_cluster_free_from_rl(), where the only test today is
lcn < 0.  Happy to drop either one if you'd rather keep it minimal.

Reproducer.  A volume whose $Bitmap covers more pages than nr_clusters
requires, with one file's data run placed in the resulting gap:

  truncate -s 13G img && mkntfs -F -f img
  mount -i -t ntfs -o rw img /mnt && dd if=/dev/urandom of=/mnt/v.bin \
      bs=4096 count=16 && umount /mnt

  # $Boot total_sectors (0x28) -> 1703936*8, i.e. nr_clusters = 1703936,
  # just above mftmirr_lcn.  lcn_empty_bits_per_page then covers 52 pages
  # while $Bitmap still spans 104, leaving indices 52..103 unbacked.
  # v.bin's single data run (3-byte LCN delta) -> LCN 3000000, index 91.

  mount -i -t ntfs -o rw img /mnt
  dd if=/dev/zero bs=4096 count=8 >> /mnt/v.bin

mount -i matters: without it the ntfs-3g helper takes the volume and this
code never runs.

A/B on v7.2-rc1 with KASAN, one arm per boot:

  unpatched, crafted image:
    BUG: KASAN: slab-out-of-bounds in ntfs_cluster_alloc+0x249e/0x2db0 [ntfs]
    Read of size 4 at addr ffff8881029dad6c by task kworker/u32:6/96
    Workqueue: writeback wb_workfn (flush-7:0)
     ntfs_cluster_alloc+0x249e/0x2db0 [ntfs]
     ntfs_attr_map_cluster+0x444/0xf50 [ntfs]
     __ntfs_write_iomap_begin+0x8b7/0x22c0 [ntfs]
     ntfs_writeback_range+0xd3/0x130 [ntfs]
    Allocated by task 2255:
     __kvmalloc_node_noprof+0x1cc/0x5d0
     ntfs_fill_super+0x16c0/0x6fd0 [ntfs]
    The buggy address is located 156 bytes to the right of
     allocated 208-byte region [ffff8881029dac00, ffff8881029dacd0)

  52 pages * sizeof(unsigned int) is 208 bytes, and index 91 is offset 364.

  clamp only:    clean; the volume mounts and the append completes
  decoder only:  clean; the run is refused
  both:          clean; the append returns EIO and the decoder logs
                 "LCN >= nr_clusters in mapping pairs array"
  pristine mkntfs volume, unpatched, same operations: clean

The write side takes the same LCN.  A kprobe caught
__ntfs_bitmap_set_bits_in_run() with start_bit=3000000 count=16, which lands
on the same array through ntfs_set_lcn_empty_bits(); KASAN reports once per
boot, so only the read above splatted.
---
 fs/ntfs/lcnalloc.c | 7 ++++++-
 fs/ntfs/runlist.c  | 7 +++++++
 2 files changed, 13 insertions(+), 1 deletion(-)

diff --git a/fs/ntfs/lcnalloc.c b/fs/ntfs/lcnalloc.c
index 835a041023a2..aa2e017a4384 100644
--- a/fs/ntfs/lcnalloc.c
+++ b/fs/ntfs/lcnalloc.c
@@ -298,7 +298,12 @@ struct runlist_element *ntfs_cluster_alloc(struct ntfs_volume *vol, const s64 st
 	clusters = count;
 	rlpos = rlsize = 0;
 	mapping = lcnbmp_vi->i_mapping;
-	i_size = i_size_read(lcnbmp_vi);
+	/*
+	 * lcn_empty_bits_per_page is sized from nr_clusters, but $Bitmap can
+	 * cover more clusters than that; bound the scan by the array.
+	 */
+	i_size = min_t(s64, i_size_read(lcnbmp_vi),
+		       ((s64)vol->nr_clusters + 7) >> 3);
 	while (1) {
 		ntfs_debug("Start of outer while loop: done_zones 0x%x, search_zone %i, pass %i, zone_start 0x%llx, zone_end 0x%llx, bmp_initial_pos 0x%llx, bmp_pos 0x%llx, rlpos %i, rlsize %i.",
 				done_zones, search_zone, pass,
diff --git a/fs/ntfs/runlist.c b/fs/ntfs/runlist.c
index cbb6576cf725..74f94b4b6c5b 100644
--- a/fs/ntfs/runlist.c
+++ b/fs/ntfs/runlist.c
@@ -880,6 +880,13 @@ struct runlist_element *ntfs_mapping_pairs_decompress(const struct ntfs_volume *
 					ntfs_error(vol->sb, "lcn == -1");
 			}
 #endif
+			/* Check lcn is within the volume. */
+			if (unlikely(lcn >= (s64)vol->nr_clusters)) {
+				ntfs_error(vol->sb,
+						"LCN >= nr_clusters in mapping pairs array.");
+				goto err_out;
+			}
+
 			/* Check lcn is not below -1. */
 			if (unlikely(lcn < -1)) {
 				ntfs_error(vol->sb, "Invalid s64 < -1 in mapping pairs array.");

---
base-commit: 4235cb24ec1e8e96843f3671ba4da2a6ccca2c7b
change-id: 20260726-b4-disp-9cd2a8a2-007c3a970c87

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

