From: Nayeon Kim <nayeoni.kim@samsung.com>
Date: Tue, 24 Nov 2026 13:52:01 +0900
Subject: [PATCH] scsi: ufs: rpmb: Return -EIO instead of SCSI result on
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ufs-3-rpmb-errno-v1-1-65b54643ca21@samsung.com>
X-B4-Tracking: v=1; b=H4sIAPAXBWsC/yWMQQ6CMBBFr0K6dsTWRqpXMS7aMoUxsZAZMSaEu
 9vK8v3891YlyISibs2qGD8kNOUC+tCoOPo8IFBfWJmTuWhtLAQLSxI4A8+vAMicJ7jaPgXnMDn
 dqWLOjIm+/+r9sbMs4YnxXVP1EbwgBPY5jnWamAbKbXe0rUQh2O1t+wGLT3W0nwAAAA==
X-Change-ID: 20261124-b4-ufs-3-rpmb-errno-94dfb88ef817
To: linux-scsi@vger.kernel.org, "Martin K. Petersen" <mkp@kernel.org>
Cc: Alim Akhtar <alim.akhtar@samsung.com>, 
 Jorge Ramirez-Ortiz <jorge.ramirez@oss.qualcomm.com>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 Bean Huo <beanhuo@micron.com>, Bart Van Assche <bvanassche@acm.org>, 
 linux-kernel@vger.kernel.org, Stanley Jhu <stanleyjhu@google.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795495921; l=2758;
 i=nayeoni.kim@samsung.com; s=20261102; h=from:subject:message-id;
 bh=bdGL8kCpC3JX6CQ4ZXGjUu6KFEVgq+FRVLoMwfb+mxQ=;
 b=wnlsK2i51g07bFO0PCnWWMLUSjpX0nWdj7ZXkYNQkbY4oNEvhgkEPccbKvPY35vmSpw3leWS/
 ZAr1jOewRBEBh7IU0o+hbOuN8qWaXYyH9Uv/WwDD3koZBzkQ/za6NgP
X-Developer-Key: i=nayeoni.kim@samsung.com; a=ed25519;
 pk=6rdU/EioX/vzm132vDyAq+TUk6SqpWqob+mz30+/n5E=
X-Endpoint-Received: by B4 Relay for nayeoni.kim@samsung.com/20261102 with auth_id=1381
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rpmb_route_frames() is documented to return a negative errno on
failure, but ufs_sec_submit() returns the value of scsi_execute_cmd()
as is. When a SECURITY PROTOCOL IN/OUT command fails, that value is a
positive SCSI result such as SAM_STAT_CHECK_CONDITION or
DID_ERROR << 16. ufs_rpmb_route_frames() passes it up and logs it as
"ret=%d". Since scsi_execute_cmd() sets RQF_QUIET, the sense data is
not logged anywhere.

handle_rpc_func_rpmb_frames(), the only caller of rpmb_route_frames(),
checks for a non-zero return, so OP-TEE still sees the failure.

Log the SCSI result and sense data in ufs_sec_submit() and convert
positive results to -EIO, as ufshcd_set_dev_pwr_mode() does.

Signed-off-by: Nayeon Kim <nayeoni.kim@samsung.com>
---
Based on 7.4/scsi-fixes because it depends on commit 7bc9b854cd68
("scsi: ufs: rpmb: Decouple device lifecycle from devres to avoid UAF").
Not urgent; fine for 7.5. Compile-tested (W=1) only.
---
 drivers/ufs/core/ufs-rpmb.c | 20 +++++++++++++++++---
 1 file changed, 17 insertions(+), 3 deletions(-)

diff --git a/drivers/ufs/core/ufs-rpmb.c b/drivers/ufs/core/ufs-rpmb.c
index 6803f3e62d78..d94633700cdf 100644
--- a/drivers/ufs/core/ufs-rpmb.c
+++ b/drivers/ufs/core/ufs-rpmb.c
@@ -19,6 +19,7 @@
 #include <linux/rpmb.h>
 #include <linux/string.h>
 #include <linux/list.h>
+#include <scsi/scsi_dbg.h>
 #include <ufs/ufshcd.h>
 #include <linux/unaligned.h>
 #include "ufshcd-priv.h"
@@ -55,10 +56,13 @@ static int ufs_sec_submit(struct ufs_rpmb_dev *ufs_rpmb, u16 spsp,
 	struct scsi_failures failures = {
 		.failure_definitions = failure_defs,
 	};
+	struct scsi_sense_hdr sshdr;
 	const struct scsi_exec_args exec_args = {
+		.sshdr = &sshdr,
 		.failures = &failures,
 	};
 	u8 cdb[12] = { };
+	int ret;
 
 	if (!sdev || !scsi_device_online(sdev))
 		return -ENODEV;
@@ -68,9 +72,19 @@ static int ufs_sec_submit(struct ufs_rpmb_dev *ufs_rpmb, u16 spsp,
 	put_unaligned_be16(spsp, &cdb[2]);
 	put_unaligned_be32(len, &cdb[6]);
 
-	return scsi_execute_cmd(sdev, cdb, send ? REQ_OP_DRV_OUT : REQ_OP_DRV_IN,
-				buffer, len, /*timeout=*/30 * HZ, /*retries=*/0,
-				&exec_args);
+	ret = scsi_execute_cmd(sdev, cdb, send ? REQ_OP_DRV_OUT : REQ_OP_DRV_IN,
+			       buffer, len, /*timeout=*/30 * HZ, /*retries=*/0,
+			       &exec_args);
+	if (ret > 0) {
+		dev_err(&ufs_rpmb->dev,
+			"SECURITY PROTOCOL %s failed: result %#x\n",
+			send ? "OUT" : "IN", ret);
+		if (scsi_sense_valid(&sshdr))
+			scsi_print_sense_hdr(sdev, NULL, &sshdr);
+		ret = -EIO;
+	}
+
+	return ret;
 }
 
 /* UFS RPMB route frames implementation */

---
base-commit: efd68f17acca65f581b9f2fa9ba50c8643ab544d
change-id: 20261124-b4-ufs-3-rpmb-errno-94dfb88ef817

