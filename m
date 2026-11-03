From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 15:03:21 -0500
Subject: [PATCH v2] btrfs: fix bio counter and bioc leak when async
 checksumming fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-btrfs-async-csum-leak-v2-1-30872bec9613@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4XM2jGdEiG68j8Mi1KmUuVhOpRIC
 P8uj7XLk9x7zgzCwbPALZkh8OjF990K+pSArU33ZPTVyqCVzkilCsshOEEjU2fRSmyxYfNGynN
 duYtTNtWwfj+Bnf/u3kdxsMTyxXbYZNui9jL0YdrDI227o0GK/jRGQkLHxnFuOCO+3m3fxLb05
 sxVhGJZlh+5AekZzwAAAA==
X-Change-ID: 20261030-btrfs-async-csum-leak-1772df5f0c32
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: Qu Wenruo <wqu@suse.com>, Christoph Hellwig <hch@lst.de>, 
 Josef Bacik <josef@toxicpanda.com>, 
 Johannes Thumshirn <johannes.thumshirn@wdc.com>, 
 John Garry <john.garry@linux.dev>, linux-btrfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793736201; l=3251;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=sZ15wckZNBlDyiOLVC9bEfAohvO3ectUWRrLDyA5+Jo=;
 b=SvIUTYUzswOF461t+ia+Mvr4QdkS5dDCzWFzYtYqa6vm3Ju6Yv/w1en7R2C3eCAZtWSAW9u2L
 ifiK38ND2fWA1pfSmFN8mySC2RaANi85jqbizdLWXKaJspdrg/xVBZx
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A single failed checksum allocation can make a later device replace
hang forever.  btrfs_submit_chunk() takes a dev-replace bio counter
reference and a bioc before it hands a write to the checksum worker.
If the checksum fails there (e.g., its allocation fails),
run_one_async_done() ends the bio but drops neither.  The counter then
never gets back to zero and the next replace waits for it:

  [    8.369171] BTRFS info (device ram0): dev_replace from /dev/ram0 (devid 1) to /dev/ram1 finished
  [   41.534247] INFO: task btrfscsum:80 blocked for more than 20 seconds.
  [   41.534391]  btrfs_rm_dev_replace_blocked+0x135/0x180
  [   41.534463]  btrfs_dev_replace_finishing+0xefe/0x13b0

The worker is only used when CONFIG_BTRFS_EXPERIMENTAL is off and the
checksum isn't a fast one, e.g., sha256.  We hit it on a sha256
filesystem.

We put the bioc and drop the counter in that error branch.  We also
put the bioc on the synchronous error path and on the btrfs_split_bio()
error path, which both only drop the counter.  With the fix, the
replace doesn't hang anymore.

This bug was identified and confirmed with the help of fault-injection
testing on a deterministic hypervisor currently under development.  The
C reproducer below however hits it within about 35s.

Fixes: f8a53bb58ec7 ("btrfs: handle checksum generation in the storage layer")
Fixes: c7c97ceff98c ("btrfs: handle bio_split() errors")
Cc: stable@vger.kernel.org # 6.6+
Reviewed-by: Qu Wenruo <wqu@suse.com>
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Changes in v2:
- Also put the bioc on the btrfs_split_bio() error path (Qu)
- Mention the sha256 / non-EXPERIMENTAL setup in the commit message (Qu)
- Add Reviewed-by from Qu
- Link to v1: https://patch.msgid.link/20261101-btrfs-async-csum-leak-v1-1-feafe7ae61e9@columbia.edu

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/btrfscsum.c
---
 fs/btrfs/bio.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/fs/btrfs/bio.c b/fs/btrfs/bio.c
index 2c6234f6182f..2e12a6d7e16f 100644
--- a/fs/btrfs/bio.c
+++ b/fs/btrfs/bio.c
@@ -624,6 +624,8 @@ static void run_one_async_done(struct btrfs_work *work, bool do_free)
 
 	/* If an error occurred we just want to clean up the bio and move on. */
 	if (bio->bi_status) {
+		btrfs_put_bioc(async->bioc);
+		btrfs_bio_counter_dec(async->bbio->inode->root->fs_info);
 		btrfs_bio_end_io(async->bbio, bio->bi_status);
 		return;
 	}
@@ -762,6 +764,7 @@ static bool btrfs_submit_chunk(struct btrfs_bio *bbio, int mirror_num)
 		split = btrfs_split_bio(fs_info, bbio, map_length);
 		if (IS_ERR(split)) {
 			status = errno_to_blk_status(PTR_ERR(split));
+			btrfs_put_bioc(bioc);
 			btrfs_bio_counter_dec(fs_info);
 			goto end_bbio;
 		}
@@ -822,6 +825,7 @@ static bool btrfs_submit_chunk(struct btrfs_bio *bbio, int mirror_num)
 	return map_length == length;
 
 fail:
+	btrfs_put_bioc(bioc);
 	btrfs_bio_counter_dec(fs_info);
 	/*
 	 * We have split the original bbio, now we have to end both the current

---
base-commit: 6255426d70f2755968bb5436ae7b43dae742ac38
change-id: 20261030-btrfs-async-csum-leak-1772df5f0c32

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

