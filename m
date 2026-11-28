From: Wesley Atwell <atwellwea@gmail.com>
Date: Sat, 28 Nov 2026 13:51:50 -0700
Subject: [PATCH] btrfs: count failed RAID1 scrub repair writes as
 uncorrectable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-btrfs-scrub-write-error-revalidated-v1-1-be9f21eede17@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/03NQQrCMBBA0auEWWcgCdJqriIuJsnEDkgqk1qF0
 rtLXbn+8P4GnVW4QzQbKK/SZW4QjbcG8kTtzigFooHgwuB9OGNatHbsWV8J3yoLI6vOisorPaT
 QwgWzc+THIVxKGMEaeCpX+fwu15s1kKgzJqWWp8P+J/0pVTw67PsXhgIBhJ0AAAA=
X-Change-ID: 20261128-btrfs-scrub-write-error-revalidated-c00a17629d27
To: Qu Wenruo <wqu@suse.com>, David Sterba <dsterba@suse.com>, 
 Chris Mason <mason@kernel.org>
Cc: linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Wesley Atwell <atwellwea@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795899109; l=4128;
 i=atwellwea@gmail.com; s=20261127; h=from:subject:message-id;
 bh=dlY6Hgy4Y/2HK0M1uDDAUTBohfq3S/cIXhDMd7g5OCs=;
 b=fsC7Ak+TCqg3MbmCSXRyY9IuSyt7dKu8JNHQeyNArnqRisGnRzxQm+d1EnfP9RsRxkm9uy3mH
 m+hID/xlR3kA+H9hRdqrjm4zSOAGRV1t+E7GfOyGZlwqjc1nRPrNHqY
X-Developer-Key: i=atwellwea@gmail.com; a=ed25519;
 pk=Buny5Y3000rYoA3OYcxvjG5W3dpuSWh28lf8IVDjANo=
X-Endpoint-Received: by B4 Relay for atwellwea@gmail.com/20261127 with auth_id=1671
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When scrub reads a damaged sector from one RAID1 mirror, it can recover
that sector from the other mirror and attempt to write it back. If the
repair write fails, scrub currently reports the sector as corrected:
the final read-error bitmap is clear, while the separate write-error
bitmap is ignored by the ordinary stripe reporter.

In a QEMU guest on the Btrfs for-next tree, btrfs scrub start -B on a
local RAID1 filesystem returned success and reported 16 corrected,
zero uncorrectable sectors after targeted read and repair-write EIO.
The damaged mirror sector remained unchanged on disk, even though the
file was still readable from its good copy. A healthy scrub reported no
errors, and a writable-repair control restored the damaged sector.

Include failed repair writes in the reporter's final error bitmap and
clear the write-error bitmap when a scrub stripe is reused. With the
same failed-write workload, scrub now exits 3, reports 16
uncorrectable and zero corrected sectors, and no longer logs those
sectors as fixed up. The healthy and successful-repair controls still
pass. This change addresses the tested mirror-based reporting path;
RAID56 parity scrub aggregates errors separately.

OpenAI Codex identified the reporting omission, drafted this change
and changelog, and prepared the QEMU scrub workload. The task asked it
to find software-only crypto and filesystem defects, prove a failure
during a legitimate Linux workload on an unmodified kernel, and fix
only findings that passed the real-user evidence gate. The unmodified
and changed kernels were tested on the Btrfs for-next base with healthy,
failed-write and successful-repair cases; an independent review checked
the source paths and raw on-disk result.

Fixes: 0096580713ff ("btrfs: scrub: introduce error reporting functionality for scrub_stripe")
Cc: stable@vger.kernel.org
Signed-off-by: Wesley Atwell <atwellwea@gmail.com>
---
The patch makes ordinary mirror scrub accounting include sectors whose
repair writes fail after a successful read from another mirror.

The task asked Codex to investigate filesystem defects, prove real-user
impact on an unmodified kernel, and fix only findings that passed that gate.
---
 fs/btrfs/scrub.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/fs/btrfs/scrub.c b/fs/btrfs/scrub.c
index c8da03e14094..b6dc7b5ec763 100644
--- a/fs/btrfs/scrub.c
+++ b/fs/btrfs/scrub.c
@@ -1023,7 +1023,9 @@ static void scrub_stripe_report_errors(struct scrub_ctx *sctx,
 	struct btrfs_fs_info *fs_info = sctx->fs_info;
 	struct btrfs_device *dev = NULL;
 	const unsigned long extent_bitmap = scrub_bitmap_read_has_extent(stripe);
-	const unsigned long error_bitmap = scrub_bitmap_read_error(stripe);
+	unsigned long error_bitmap;
+	unsigned long read_error_bitmap;
+	unsigned long flags;
 	u64 physical = 0;
 	int nr_data_sectors = 0;
 	int nr_meta_sectors = 0;
@@ -1063,6 +1065,12 @@ static void scrub_stripe_report_errors(struct scrub_ctx *sctx,
 	}
 
 skip:
+	read_error_bitmap = scrub_bitmap_read_error(stripe);
+	spin_lock_irqsave(&stripe->write_error_lock, flags);
+	bitmap_or(&error_bitmap, &read_error_bitmap, &stripe->write_error_bitmap,
+		  stripe->nr_sectors);
+	spin_unlock_irqrestore(&stripe->write_error_lock, flags);
+
 	for_each_set_bit(sector_nr, &extent_bitmap, stripe->nr_sectors) {
 		const u64 sector_logical = stripe->logical +
 					   ((u64)sector_nr << fs_info->sectorsize_bits);
@@ -1796,6 +1804,12 @@ static int scrub_find_fill_first_stripe(struct btrfs_block_group *bg,
 
 static void scrub_reset_stripe(struct scrub_stripe *stripe)
 {
+	unsigned long flags;
+
+	spin_lock_irqsave(&stripe->write_error_lock, flags);
+	stripe->write_error_bitmap = 0;
+	spin_unlock_irqrestore(&stripe->write_error_lock, flags);
+
 	scrub_stripe_reset_bitmaps(stripe);
 
 	stripe->nr_meta_extents = 0;

---
base-commit: 14bf1d1d36414abf5f7f5b8e69a1810617c5f22f
change-id: 20261128-btrfs-scrub-write-error-revalidated-c00a17629d27

Best regards,
-- 
Wesley Atwell <atwellwea@gmail.com>

