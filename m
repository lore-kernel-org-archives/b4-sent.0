From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 11:02:10 +0900
Subject: [PATCH v4 2/5] scsi-disk: Report zone errors with their ZBC sense
 codes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-zoned-ufs-v4b-v4-2-f90239d12a55@samsung.com>
References: <20261126-zoned-ufs-v4b-v4-0-f90239d12a55@samsung.com>
In-Reply-To: <20261126-zoned-ufs-v4b-v4-0-f90239d12a55@samsung.com>
To: qemu-devel@nongnu.org
Cc: Jeuk Kim <jeuk20.kim@samsung.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Fam Zheng <fam@euphon.net>, Kevin Wolf <kwolf@redhat.com>, 
 Hanna Reitz <hreitz@redhat.com>, qemu-block@nongnu.org, 
 Fabiano Rosas <farosas@suse.de>, Laurent Vivier <lvivier@redhat.com>, 
 Pierrick Bouvier <pierrick.bouvier@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Sam Li <faithilikerun@gmail.com>, Stefan Hajnoczi <stefanha@redhat.com>, 
 Stanley Jhu <stanleyjhu@google.com>, 
 Keoseong Park <keosung.park@samsung.com>, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795658528; l=3383;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=RtJEtOqUcVPZOmbAoYOQxqGUl03XOQZDoLQB2Vd6q/M=;
 b=ZWuz6BUBbZ5PGfvwLesYCxv/bHWY0FNE8nFH8bX8iCpVarrFIgzroG8I/ca7StcWLq6W1YyD6
 ZVBnA+lOCHYBPCSyJatkbvOVLKLWhZHJoAZr0FNaYGmPVmqaLdbp133
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A zoned block driver fails a write that breaks the zone rules with a
BLK_ZE_* errno. scsi-disk reports these as ABORTED COMMAND under the
werror policy. So the guest retries, and with werror=stop the VM stops
again on resume.

On a host-managed backend, report the ZBC sense code instead, whatever
the error policy, as for a reservation conflict. A write to a full zone
gets INVALID FIELD IN CDB. The mapping goes to scsi/utils.c for zoned
UFS to share.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 hw/scsi/scsi-disk.c  | 11 ++++++++++-
 include/scsi/utils.h |  1 +
 scsi/utils.c         | 28 ++++++++++++++++++++++++++++
 3 files changed, 39 insertions(+), 1 deletion(-)

diff --git a/hw/scsi/scsi-disk.c b/hw/scsi/scsi-disk.c
index a2df3a4ec4..643247da0c 100644
--- a/hw/scsi/scsi-disk.c
+++ b/hw/scsi/scsi-disk.c
@@ -246,7 +246,16 @@ static bool scsi_handle_rw_error(SCSIDiskReq *r, int ret, bool acct_failed)
         r->req.host_status = -1;
     }
 
-    if (ret < 0) {
+    if (ret < 0 && blk_get_zone_model(s->qdev.conf.blk) == BLK_Z_HM &&
+        scsi_sense_from_zone_errno(-ret, &sense)) {
+        /*
+         * The guest broke the zone rules. As for a reservation conflict,
+         * a retry fails the same way, so report the error whatever the
+         * error policy, and do not post it to QMP.
+         */
+        status = CHECK_CONDITION;
+        error = 0;
+    } else if (ret < 0) {
         status = scsi_sense_from_errno(-ret, &sense);
         error = -ret;
     } else {
diff --git a/include/scsi/utils.h b/include/scsi/utils.h
index d16c264b22..93178e7528 100644
--- a/include/scsi/utils.h
+++ b/include/scsi/utils.h
@@ -148,6 +148,7 @@ int scsi_cdb_length(uint8_t *buf);
 #endif
 
 int scsi_sense_from_errno(int errno_value, SCSISense *sense);
+bool scsi_sense_from_zone_errno(int errno_value, SCSISense *sense);
 int scsi_sense_from_host_status(uint8_t host_status, SCSISense *sense);
 
 #endif
diff --git a/scsi/utils.c b/scsi/utils.c
index 9eb41aefdf..cdf3ef11d4 100644
--- a/scsi/utils.c
+++ b/scsi/utils.c
@@ -17,6 +17,7 @@
 #include "scsi/constants.h"
 #include "scsi/utils.h"
 #include "qemu/bswap.h"
+#include "block/block-common.h"
 
 uint32_t scsi_data_cdb_xfer(uint8_t *buf)
 {
@@ -597,6 +598,33 @@ const char *scsi_command_name(uint8_t cmd)
     return names[cmd];
 }
 
+/*
+ * The sense code of a zone error, one of the BLK_ZE_* errnos with which a
+ * zoned block driver fails a request that breaks the zone rules. Other
+ * drivers use these errnos for other errors, so only ask for the errors of
+ * a zoned backend.
+ */
+bool scsi_sense_from_zone_errno(int errno_value, SCSISense *sense)
+{
+    switch (errno_value) {
+    case BLK_ZE_UNALIGNED_WRITE:
+        *sense = SENSE_CODE(UNALIGNED_WRITE);
+        return true;
+    case BLK_ZE_BOUNDARY:
+        *sense = SENSE_CODE(WRITE_BOUNDARY_VIOLATION);
+        return true;
+    case BLK_ZE_FULL:
+        *sense = SENSE_CODE(INVALID_FIELD);
+        return true;
+    case BLK_ZE_OPEN_RESOURCE:
+    case BLK_ZE_ACTIVE_RESOURCE:
+        *sense = SENSE_CODE(INSUFFICIENT_ZONE_RESOURCES);
+        return true;
+    default:
+        return false;
+    }
+}
+
 int scsi_sense_from_errno(int errno_value, SCSISense *sense)
 {
     switch (errno_value) {

-- 
2.43.0

