From: Mark Korenberg <socketpair@gmail.com>
Date: Thu, 05 Nov 2026 00:25:05 +0500
Subject: [PATCH 1/2] ublk: publish a new device by its id only once it is
 set up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-ublk-del-gendisk-hang-v1-1-913a91a4314d@gmail.com>
References: <20261105-ublk-del-gendisk-hang-v1-0-913a91a4314d@gmail.com>
In-Reply-To: <20261105-ublk-del-gendisk-hang-v1-0-913a91a4314d@gmail.com>
To: Ming Lei <tom.leiming@gmail.com>
Cc: Jens Axboe <axboe@kernel.dk>, linux-block@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ming Lei <ming.lei@redhat.com>, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793820305; l=2820;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=kErRrExpI2LtJAMvv3KNrq5h1atq5uq7x5u9yvNiW0k=;
 b=wGCIBYj0ASQ8ToPwvpJBCU6doUyE+kmK3ox+J7uRIlsmHnyZ3vkPISWKJxGdYVtxgUnJYIMVF
 1DeqksiQfXGB0CdULrSsihuqh1eb5n/FCB9ykRmxHE4nnD2eq08geMH
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ADD_DEV stores the device in ublk_index_idr when it allocates the id,
and control commands find it there as soon as ublk_add_chdev() has
initialized its struct device, before the char device is added. If
dev_set_name() or cdev_device_add() then fails, ublk_add_chdev() drops
the initial reference to free the device. A DEL_DEV that found the
device meanwhile waits for ublk_ctl_mutex, then calls ublk_remove():
cdev_device_del() of a device that was never added, and a second put of
the initial reference, which frees the device under the callers still
holding references.

Reserve the id with a NULL entry, which idr_find() and the idr iterators
skip, and store the device once ublk_add_chdev() succeeded.

Fixes: 71f28f3136af ("ublk_drv: add io_uring based userspace block driver")
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 drivers/block/ublk_drv.c | 23 +++++++++++++++++++++--
 1 file changed, 21 insertions(+), 2 deletions(-)

diff --git a/drivers/block/ublk_drv.c b/drivers/block/ublk_drv.c
index 72e9c435208c..14d2823a92e5 100644
--- a/drivers/block/ublk_drv.c
+++ b/drivers/block/ublk_drv.c
@@ -4405,14 +4405,18 @@ static int ublk_alloc_dev_number(struct ublk_device *ub, int idx)
 	int i = idx;
 	int err;
 
+	/*
+	 * Only reserve the id: the device is published by
+	 * ublk_publish_dev_number() once it is fully set up.
+	 */
 	spin_lock(&ublk_idr_lock);
 	/* allocate id, if @id >= 0, we're requesting that specific id */
 	if (i >= 0) {
-		err = idr_alloc(&ublk_index_idr, ub, i, i + 1, GFP_NOWAIT);
+		err = idr_alloc(&ublk_index_idr, NULL, i, i + 1, GFP_NOWAIT);
 		if (err == -ENOSPC)
 			err = -EEXIST;
 	} else {
-		err = idr_alloc(&ublk_index_idr, ub, 0, UBLK_MAX_UBLKS,
+		err = idr_alloc(&ublk_index_idr, NULL, 0, UBLK_MAX_UBLKS,
 				GFP_NOWAIT);
 	}
 	spin_unlock(&ublk_idr_lock);
@@ -4423,6 +4427,19 @@ static int ublk_alloc_dev_number(struct ublk_device *ub, int idx)
 	return err;
 }
 
+/*
+ * Make the device visible to control commands by its id. Before its char
+ * device is added, DEL_DEV could find it and remove a char device that was
+ * never added, and drop the reference that ublk_add_chdev() drops on
+ * failure.
+ */
+static void ublk_publish_dev_number(struct ublk_device *ub)
+{
+	spin_lock(&ublk_idr_lock);
+	WARN_ON_ONCE(idr_replace(&ublk_index_idr, ub, ub->ub_number) != NULL);
+	spin_unlock(&ublk_idr_lock);
+}
+
 static void ublk_free_dev_number(struct ublk_device *ub)
 {
 	spin_lock(&ublk_idr_lock);
@@ -4991,6 +5008,8 @@ static int ublk_ctrl_add_dev(const struct ublksrv_ctrl_cmd *header)
 	 * ublk_add_chdev() will cleanup everything if it fails.
 	 */
 	ret = ublk_add_chdev(ub);
+	if (!ret)
+		ublk_publish_dev_number(ub);
 	goto out_unlock;
 
 out_deinit_queues:

-- 
2.56.0

