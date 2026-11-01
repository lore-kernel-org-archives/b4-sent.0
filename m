From: Mani Tofigh <mt4022@columbia.edu>
Date: Sun, 01 Nov 2026 13:39:52 -0500
Subject: [PATCH] btrfs: fix bio counter and bioc leak when async
 checksumming fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-btrfs-async-csum-leak-v1-1-feafe7ae61e9@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBA0auQWTtJW6IkXoWwKMNUB6SaDhAI4
 e5WXL7F/zsoJ2GFe7FD4kVU3jHDXgqgp48PRumywRl3s6Y02E4pKHrdIiHpPOKL/YC2qlwXrsF
 Q6SC3n8RB1vNbN3/r3PZM028Gx/EFeGIUMnkAAAA=
X-Change-ID: 20261030-btrfs-async-csum-leak-1772df5f0c32
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>
Cc: Qu Wenruo <wqu@suse.com>, Christoph Hellwig <hch@lst.de>, 
 Josef Bacik <josef@toxicpanda.com>, 
 Johannes Thumshirn <johannes.thumshirn@wdc.com>, 
 linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793558392; l=2369;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=mGiLrTH5AqlN5JS+ipDmST7KGFMjGScKRUdjepxjagw=;
 b=i817B+Hk0R44YFLbkmJkWr40ppVxvcWEv5xLvPF4pmkmoUO7WZFnyFJg6PlLMqTOdsEBNgl+w
 BTgE7frgH3tA9Dg6T79LE7JgyO6ikbL2mpIpYqeONCt8vUgikFsn3XI
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A single failed checksum allocation can make a later device replace
hang forever.  btrfs_submit_chunk() takes a dev-replace bio counter
reference and a bioc before it hands a write to the checksum worker.
If the checksum fails there (eg its allocation fails),
run_one_async_done() ends the bio but drops neither.  The counter then
never gets back to zero and the next replace waits for it:

  [    8.369171] BTRFS info (device ram0): dev_replace from /dev/ram0 (devid 1) to /dev/ram1 finished
  [   41.534247] INFO: task btrfscsum:80 blocked for more than 20 seconds.
  [   41.534391]  btrfs_rm_dev_replace_blocked+0x135/0x180
  [   41.534463]  btrfs_dev_replace_finishing+0xefe/0x13b0

Put the bioc and drop the counter in that error branch as the
synchronous error path does.  Also put the bioc on the synchronous
path, which only drops the counter.  With the fix, the replace
finishes.

This bug was identified and confirmed with the help of fault-injection
testing on a deterministic hypervisor currently under development.  The
C reproducer below however hits it within about 35s.

Fixes: f8a53bb58ec7 ("btrfs: handle checksum generation in the storage layer")
Cc: stable@vger.kernel.org # 6.6+
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/btrfscsum.c
---
 fs/btrfs/bio.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/btrfs/bio.c b/fs/btrfs/bio.c
index 2c6234f6182f..a508f4abd3a3 100644
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
@@ -822,6 +824,7 @@ static bool btrfs_submit_chunk(struct btrfs_bio *bbio, int mirror_num)
 	return map_length == length;
 
 fail:
+	btrfs_put_bioc(bioc);
 	btrfs_bio_counter_dec(fs_info);
 	/*
 	 * We have split the original bbio, now we have to end both the current

---
base-commit: 5e6c45aaaf93343c7f8a1cde9797080238af5c1b
change-id: 20261030-btrfs-async-csum-leak-1772df5f0c32

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

