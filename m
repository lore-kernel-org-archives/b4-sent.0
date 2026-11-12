From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 12 Nov 2026 10:35:29 +0900
Subject: [PATCH] dm: fail a REQ_PREFLUSH bio with data when its preflush
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-dm-flush-data-error-v1-1-c83d3f8f3ac4@samsung.com>
X-B4-Tracking: v=1; b=H4sIAOAX9WoC/x2MQQqAIBAAvxJ7bkGLSvpKdBDdaqE01oog+nvS3
 OYw80AiYUrQFw8IXZw4hiy6LMAtNsyE7LNDpapWZ9BvOK1nWtDbwyKJRMGmNV1tGm+ccpDLXWj
 i+78O4/t+fAtuAWUAAAA=
To: Alasdair Kergon <agk@redhat.com>, Mike Snitzer <snitzer@kernel.org>, 
 Mikulas Patocka <mpatocka@redhat.com>, 
 Benjamin Marzinski <bmarzins@redhat.com>, dm-devel@lists.linux.dev
Cc: Tejun Heo <tj@kernel.org>, Brian Foster <bfoster@redhat.com>, 
 linux-xfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794447328; l=2208;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=q6PUE0uUyF22bIWKZKcR0Enr0oPYObD9+qpBd6oRddE=;
 b=FH2KTDpAwuT5PIkA91LGgmDPbmmYYbqmsr8/Bs/at2zGx7QGekF57ryKj9WRohgYRm8rWTnRK
 y2C6XvoDU6fCbR5KP/Nlzpx/BOQa4ykhAf0f7/V7tnq4tA9iiVwKoNQ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a bio with REQ_PREFLUSH and data, dm core may send an empty flush
first. If the flush fails, __dm_io_complete() still reissues the bio
without REQ_PREFLUSH and drops the error. When that write succeeds,
the XFS log keeps running and fsync() can return 0.

End the bio with the flush error instead of writing the data, as
blk-mq does.

Fixes: 6a8736d10cb4 ("dm: relax ordering of bio-based flush implementation")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on v7.4-rc2: XFS on a two-device linear table whose second
device (dm-flakey, no data) fails every flush. Before, 200 of 200
fsyncs of one writer return 0. After, the log write fails with -EIO
and XFS shuts down.

Kernels before v6.18 have a different condition here and need a
separate backport.

fstests xfs/438 uses dm-flakey targets around a linear target for the
log to fail writes. dm-flakey fails the flush clones too. With this
patch, XFS shuts down on the first log write with REQ_PREFLUSH after
the errors start, before a metadata write fails. The test still
passes. A series for fstests moves xfs/438 to the buf_ioerror error
tag.
---
 drivers/md/dm.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/md/dm.c b/drivers/md/dm.c
index 1881d86111f..0f6934e0008 100644
--- a/drivers/md/dm.c
+++ b/drivers/md/dm.c
@@ -983,7 +983,7 @@ static void __dm_io_complete(struct dm_io *io, bool first_stage)
 	if (requeued)
 		return;
 
-	if (unlikely(requeue_flush_with_data)) {
+	if (unlikely(requeue_flush_with_data) && !io_error) {
 		/*
 		 * Preflush done for flush with data, reissue
 		 * without REQ_PREFLUSH.
@@ -991,7 +991,7 @@ static void __dm_io_complete(struct dm_io *io, bool first_stage)
 		bio->bi_opf &= ~REQ_PREFLUSH;
 		queue_io(md, bio);
 	} else {
-		/* done with normal IO or empty flush */
+		/* done with normal IO, empty flush or failed preflush */
 		if (io_error)
 			bio->bi_status = io_error;
 		bio_endio(bio);

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261111-dm-flush-data-error-5687385d8c0c

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

