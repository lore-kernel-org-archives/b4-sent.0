From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 29 Oct 2026 09:51:24 +0900
Subject: [PATCH] nvme: unregister when pr_register() is given a zero new
 key
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-nvme-pr-unreg-v1-1-b4657ad4e98e@samsung.com>
X-B4-Tracking: v=1; b=H4sIAIuY4moC/x3MQQqAIBBA0avErBtQC4muEi3ExppFJiNJEN49a
 fkW/7+QSZgyzN0LQoUzX7FB9x34w8WdkLdmMMpYrcyEsZyESfCOQjuaMTirQqDBD9CaJBT4+X/
 LWusH5YuPwl8AAAA=
To: Keith Busch <kbusch@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Sagi Grimberg <sagi@grimberg.me>
Cc: Jens Axboe <axboe@kernel.dk>, 
 Mike Christie <michael.christie@oracle.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793235083; l=1781;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=mAU8OTdvinewhOZxDTmeXGacEZAsamAJlbTQrV18Lu8=;
 b=c5q4qcV2O2rZi5rHmmEktc3SJVT8gpMB9op5eXzH9YJ52W2Cn/7S9he5kMvOjX8OuAtFmyTey
 Qn9UwWPeegeBs9CcwDecacqBZ51x/r2eHAnpLrCK7rJ69hmU4Jj9jw9
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The block layer PR API defines a zero new_key in pr_register() as
unregistering old_key. nvme_pr_register() sends Replace Reservation
Key with a zero NRKEY instead. The host stays registered with key 0,
and its next registration with another key fails with Reservation
Conflict.

The pNFS SCSI layout client unregisters this way at umount. A later
mount cannot register and sends all I/O through the metadata server.

Send Unregister Reservation Key when new_key is zero.

Fixes: 1d277a637a71 ("NVMe: Add persistent reservation ops")
Cc: stable@vger.kernel.org
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested with IOC_PR_REGISTER on an nvmet nvme-loop namespace and on
dm-linear over it. Registering a new key after unregister now works.
A wrong old_key still gets Reservation Conflict.
---
 drivers/nvme/host/pr.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/nvme/host/pr.c b/drivers/nvme/host/pr.c
index fe7dbe2648..d8b6ac4d83 100644
--- a/drivers/nvme/host/pr.c
+++ b/drivers/nvme/host/pr.c
@@ -128,8 +128,12 @@ static int nvme_pr_register(struct block_device *bdev, u64 old_key, u64 new_key,
 	data.crkey = cpu_to_le64(old_key);
 	data.nrkey = cpu_to_le64(new_key);
 
-	cdw10 = old_key ? NVME_PR_REGISTER_ACT_REPLACE :
-		NVME_PR_REGISTER_ACT_REG;
+	if (!new_key)
+		cdw10 = NVME_PR_REGISTER_ACT_UNREG;
+	else if (old_key)
+		cdw10 = NVME_PR_REGISTER_ACT_REPLACE;
+	else
+		cdw10 = NVME_PR_REGISTER_ACT_REG;
 	cdw10 |= (flags & PR_FL_IGNORE_KEY) ? NVME_PR_IGNORE_KEY : 0;
 	cdw10 |= NVME_PR_CPTPL_PERSIST;
 

---
base-commit: 65ba8f34ec886ec72b2c07ddc8cf3d815c32869d
change-id: 20261028-nvme-pr-unreg-24fa60ffe3c3

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

