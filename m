From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 11:02:12 +0900
Subject: [PATCH v4 4/5] hw/ufs: Support for Zoned UFS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-zoned-ufs-v4b-v4-4-f90239d12a55@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795658529; l=39002;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=ItXeLzwGYJWUGH21JHvTieXxFHL1eT04BNIMH6V26Js=;
 b=Eh1vOgso5g1IJRdBD9aPAQnBaXJZRU47Ca/U6Pr1L93NdLPIm7lmZSR6F84UJyR4EpOtDEGs4
 oyNkyQk0evjD5J9bV9vHGxSDncOxGN/6cKXvyCG9fBkNS98ZaRI0XUr
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A logical unit on a host-managed zoned drive becomes a ZBC host-managed
device with the drive's zones. The drive keeps them and enforces
conventional zones and open zone limits.

ZBC completes OPEN ZONE of a full zone without a change, and FINISH ALL
skips empty zones. The image fails the first and fills the second, so
the logical unit checks the zone conditions first. OPEN ALL checks the
open zone limit first, since ZBC opens no zone if not all closed zones
fit. FINISH ALL finishes the closed zones last, as the image needs a
free open zone for each.

The zone commands run in a coroutine, which starts no more zone actions
once its request is cancelled. It can resume outside the controller's
handlers, so it completes requests under the reentrancy guard.

Writes go through scsi-hd, which reports the zone errors of the drive.
WRITE SAME, not a UFS command, is rejected, as the image does not check
write-zeroes requests against the zones.

Gap zones are not modelled, and ZBC cannot report an active zone limit.
So a zone capacity below the zone length is rejected, as is an active
zone limit below the number of sequential zones.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 hw/ufs/lu.c         | 886 +++++++++++++++++++++++++++++++++++++++++++++++++++-
 hw/ufs/trace-events |   5 +
 hw/ufs/ufs.c        |  16 +
 hw/ufs/ufs.h        |   8 +
 include/block/ufs.h |  15 +
 5 files changed, 921 insertions(+), 9 deletions(-)

diff --git a/hw/ufs/lu.c b/hw/ufs/lu.c
index bbb0554fb0..40fd9194d5 100644
--- a/hw/ufs/lu.c
+++ b/hw/ufs/lu.c
@@ -20,6 +20,11 @@
 #include "ufs.h"
 
 #define SCSI_COMMAND_FAIL (-1)
+#define REPORT_ZONES_HEADER_SIZE 64
+#define REPORT_ZONES_DESC_SIZE 64
+#define ZBC_VPD_B6_LEN 64
+/* zones per zone report of the drive */
+#define UFS_ZBC_REPORT_BATCH 256
 
 static void ufs_build_upiu_sense_data(UfsRequest *req, uint8_t *sense,
                                       uint32_t sense_len)
@@ -58,6 +63,70 @@ static void ufs_build_scsi_response_upiu(UfsRequest *req, uint8_t *sense,
                           status, data_segment_length);
 }
 
+/*
+ * The wrapped scsi-hd is a direct-access (TYPE_DISK) device, so every
+ * command that a zoned LU forwards to it, including MODE SENSE, takes the
+ * regular disk path. Only the identification differs: a zoned LU reports
+ * itself as a host-managed zoned block device. Set the peripheral device
+ * type of the INQUIRY data that scsi-hd built to TYPE_ZBC, and add the ZBC
+ * device characteristics VPD page (emulated in ufs_emulate_zbc_cmd()) to the
+ * list of supported VPD pages. Since WRITE SAME is rejected, also clear its
+ * maximum length in the Block Limits VPD page and its bits in the Logical
+ * Block Provisioning VPD page. scsi-hd pads its data with zeros up to the
+ * allocation length, and len is never larger than that.
+ */
+static void ufs_zoned_fixup_inquiry(const uint8_t *cdb, uint8_t *buf,
+                                    uint32_t len)
+{
+    uint8_t page_len;
+
+    if (len == 0) {
+        return;
+    }
+
+    buf[0] = TYPE_ZBC;
+
+    if (!(cdb[1] & 0x1) || len < 4) {
+        return;
+    }
+
+    /* WRITE SAME is rejected, see ufs_emulate_zbc_cmd() */
+    if (cdb[2] == 0xb0) {
+        /* Block Limits: maximum WRITE SAME length */
+        if (len > 36) {
+            memset(&buf[36], 0, MIN(len, 44) - 36);
+        }
+        return;
+    }
+    if (cdb[2] == 0xb2) {
+        /* Logical Block Provisioning: clear LBPWS and LBPWS10 */
+        if (len > 5) {
+            buf[5] &= ~0x60;
+        }
+        return;
+    }
+    if (cdb[2] != 0x00) {
+        return;
+    }
+
+    /* Supported VPD pages, in ascending order: 0xb6 goes last */
+    page_len = buf[3];
+    if (page_len < 255 && !memchr(&buf[4], 0xb6, MIN(page_len, len - 4))) {
+        buf[3] = page_len + 1;
+        if (4 + page_len < len) {
+            buf[4 + page_len] = 0xb6;
+        }
+    }
+}
+
+/* Whether a zoned LU adjusts the data that scsi-hd returns for cdb */
+static bool ufs_zoned_fixup_cmd(const uint8_t *cdb)
+{
+    return cdb[0] == INQUIRY ||
+           (cdb[0] == SERVICE_ACTION_IN_16 &&
+            (cdb[1] & 0x1f) == SAI_READ_CAPACITY_16);
+}
+
 #define UFS_GROUP_NUMBER_MASK 0x1F
 #define UFS_WB_GROUP_NUMBER_DEFAULT 0x00 /* 00000b */
 #define UFS_WB_GROUP_NUMBER_PINNED 0x18 /* 11000b */
@@ -204,9 +273,40 @@ static void ufs_scsi_command_cancelled(SCSIRequest *scsi_req)
 static QEMUSGList *ufs_get_sg_list(SCSIRequest *scsi_req)
 {
     UfsRequest *req = scsi_req->hba_private;
+    UfsLu *lu = container_of(scsi_req->bus, UfsLu, bus);
+
+    /*
+     * INQUIRY and READ CAPACITY(16) data of a zoned LU go through
+     * ufs_scsi_transfer_data()
+     */
+    if (lu->zoned && ufs_zoned_fixup_cmd(scsi_req->cmd.buf)) {
+        return NULL;
+    }
+
     return req->sg;
 }
 
+static void ufs_scsi_transfer_data(SCSIRequest *scsi_req, uint32_t len)
+{
+    UfsRequest *req = scsi_req->hba_private;
+    uint8_t *buf = scsi_req_get_buf(scsi_req);
+
+    /* Only these commands of a zoned LU have no SG list */
+    assert(ufs_zoned_fixup_cmd(scsi_req->cmd.buf) && req->sg);
+
+    if (scsi_req->cmd.buf[0] == INQUIRY) {
+        ufs_zoned_fixup_inquiry(scsi_req->cmd.buf, buf, len);
+    } else if (len > 12) {
+        /*
+         * RC BASIS 1: the returned LBA is the last one of the LU, not of
+         * the conventional zones at its start
+         */
+        buf[12] = (buf[12] & ~0x30) | 0x10;
+    }
+    dma_buf_read(buf, len, NULL, req->sg, MEMTXATTRS_UNSPECIFIED);
+    scsi_req_continue(scsi_req);
+}
+
 static const struct SCSIBusInfo ufs_scsi_info = {
     .tcq = true,
     .max_target = 0,
@@ -214,6 +314,7 @@ static const struct SCSIBusInfo ufs_scsi_info = {
     .max_channel = 0,
 
     .get_sg_list = ufs_get_sg_list,
+    .transfer_data = ufs_scsi_transfer_data,
     .complete = ufs_scsi_command_complete,
     .cancel = ufs_scsi_command_cancelled,
 };
@@ -346,6 +447,636 @@ static int ufs_emulate_wlun_inquiry(UfsRequest *req, uint8_t *outbuf,
     return SCSI_INQUIRY_LEN;
 }
 
+/* ZBC device characteristics VPD page */
+static int ufs_emulate_zbc_vpd_page(UfsLu *lu, uint8_t *outbuf)
+{
+    uint32_t max_open = blk_get_max_open_zones(lu->scsi_dev->conf.blk);
+
+    memset(outbuf, 0, ZBC_VPD_B6_LEN);
+    outbuf[0] = TYPE_ZBC;
+    outbuf[1] = 0xb6;
+    stw_be_p(&outbuf[2], ZBC_VPD_B6_LEN - 4);
+
+    /*
+     * URSWRZ: reads are not restricted by the write pointer. qcow2 does not
+     * restrict them, and Linux exposes no host-managed drive that does.
+     */
+    outbuf[4] = 0x01;
+    /* optimal number of open sequential write preferred zones */
+    stl_be_p(&outbuf[8], 0xffffffff);
+    /* optimal number of non-seq. written seq. write preferred zones */
+    stl_be_p(&outbuf[12], 0xffffffff);
+    /* maximum number of open sequential write required zones */
+    stl_be_p(&outbuf[16], max_open ? max_open : 0xffffffff);
+    /* zone alignment method 0 and starting LBA granularity 0: zone length */
+
+    return ZBC_VPD_B6_LEN;
+}
+
+static const struct SCSISense sense_code_INSUFFICIENT_RESOURCES = {
+    .key = ILLEGAL_REQUEST, .asc = 0x55, .ascq = 0x03
+};
+
+/*
+ * A ZBC IN or ZBC OUT command. It runs in a coroutine, since the zones are
+ * those of the drive and the zoned block layer API reads and changes them.
+ * It holds a reference to the drive and copies what it needs of the LU, so
+ * that it can run on after the request is cancelled and the LU is gone.
+ */
+typedef struct UfsZbcCmd {
+    BlockBackend *blk;
+    uint8_t lun;
+    uint64_t nr_blocks;
+    uint64_t zone_size;
+    uint32_t nr_zones;
+    /* NULL once the UFS request is cancelled, see ufs_zbc_cancel() */
+    UfsRequest *req;
+    uint8_t cdb[UFS_CDB_SIZE];
+    /* REPORT ZONES data */
+    uint8_t *outbuf;
+    uint32_t outbuf_len;
+    uint32_t len;
+    int status;
+    SCSISense sense;
+} UfsZbcCmd;
+
+/* Byte offset of the zone with index idx */
+static inline int64_t ufs_zone_offset(UfsZbcCmd *zc, uint32_t idx)
+{
+    return (int64_t)(idx * zc->zone_size) << UFS_BLOCK_SIZE_SHIFT;
+}
+
+static void ufs_zbc_fail(UfsZbcCmd *zc, SCSISense sense)
+{
+    zc->status = CHECK_CONDITION;
+    zc->sense = sense;
+}
+
+static void ufs_zbc_fail_errno(UfsZbcCmd *zc, int ret)
+{
+    if (scsi_sense_from_zone_errno(-ret, &zc->sense)) {
+        zc->status = CHECK_CONDITION;
+    } else {
+        zc->status = scsi_sense_from_errno(-ret, &zc->sense);
+    }
+}
+
+/* REPORT ZONES reporting options */
+static bool ufs_zbc_report_option_valid(uint8_t rep_opts)
+{
+    switch (rep_opts) {
+    case 0x00 ... 0x07:
+    case 0x10:
+    case 0x11:
+    case 0x3e:
+    case 0x3f:
+        return true;
+    default:
+        return false;
+    }
+}
+
+/*
+ * The BLK_ZS_* zone states have the values of the ZBC zone conditions, and
+ * the BLK_ZT_* zone types those of the ZBC zone types.
+ */
+QEMU_BUILD_BUG_ON(BLK_ZS_NOT_WP != 0x0 || BLK_ZS_EMPTY != 0x1 ||
+                  BLK_ZS_IOPEN != 0x2 || BLK_ZS_EOPEN != 0x3 ||
+                  BLK_ZS_CLOSED != 0x4 || BLK_ZS_RDONLY != 0xd ||
+                  BLK_ZS_FULL != 0xe || BLK_ZS_OFFLINE != 0xf);
+QEMU_BUILD_BUG_ON(BLK_ZT_CONV != 0x1 || BLK_ZT_SWR != 0x2 ||
+                  BLK_ZT_SWP != 0x3);
+
+static bool ufs_zbc_report_option_match(BlockZoneState state, uint8_t rep_opts)
+{
+    switch (rep_opts) {
+    case 0x00: /* all zones */
+    case 0x3e: /* all zones except gap zones */
+        return true;
+    case 0x01:
+        return state == BLK_ZS_EMPTY;
+    case 0x02:
+        return state == BLK_ZS_IOPEN;
+    case 0x03:
+        return state == BLK_ZS_EOPEN;
+    case 0x04:
+        return state == BLK_ZS_CLOSED;
+    case 0x05:
+        return state == BLK_ZS_FULL;
+    case 0x06:
+        return state == BLK_ZS_RDONLY;
+    case 0x07:
+        return state == BLK_ZS_OFFLINE;
+    case 0x3f:
+        return state == BLK_ZS_NOT_WP;
+    default:
+        /*
+         * Reset write pointer recommended and non-sequential write resources
+         * active zones: none exist.
+         */
+        return false;
+    }
+}
+
+/*
+ * zc->outbuf holds at least the header and otherwise no more than the smaller
+ * of the allocation length and the whole report.
+ */
+static void coroutine_fn ufs_zbc_report_zones(UfsZbcCmd *zc)
+{
+    uint8_t *cdb = zc->cdb;
+    uint64_t nr_blocks = zc->nr_blocks;
+    uint64_t zone_start_lba = ldq_be_p(&cdb[2]);
+    uint32_t alloc_len = ldl_be_p(&cdb[10]);
+    uint8_t rep_opts = cdb[14] & 0x3f;
+    bool partial = cdb[14] & 0x80;
+    g_autofree BlockZoneDescriptor *zones = NULL;
+    uint32_t limit, max_descs, nr_descs = 0;
+    uint32_t offset = REPORT_ZONES_HEADER_SIZE;
+    uint32_t idx;
+
+    trace_ufs_zbc_report_zones(zc->lun, zone_start_lba, alloc_len, rep_opts);
+
+    if ((cdb[1] & 0x1f) != UFS_ZBC_REPORT_ZONES ||
+        !ufs_zbc_report_option_valid(rep_opts)) {
+        ufs_zbc_fail(zc, SENSE_CODE(INVALID_FIELD));
+        return;
+    }
+
+    if (zone_start_lba >= nr_blocks) {
+        ufs_zbc_fail(zc, SENSE_CODE(LBA_OUT_OF_RANGE));
+        return;
+    }
+
+    if (alloc_len == 0) {
+        return;
+    }
+
+    assert(zc->outbuf_len >= REPORT_ZONES_HEADER_SIZE);
+    limit = MIN(alloc_len, zc->outbuf_len);
+    max_descs = limit > REPORT_ZONES_HEADER_SIZE ?
+                (limit - REPORT_ZONES_HEADER_SIZE) / REPORT_ZONES_DESC_SIZE :
+                0;
+
+    /* The zone list length counts every matching zone, so look at them all */
+    zones = g_new(BlockZoneDescriptor, UFS_ZBC_REPORT_BATCH);
+    idx = zone_start_lba / zc->zone_size;
+    while (idx < zc->nr_zones) {
+        unsigned int i, n = MIN(UFS_ZBC_REPORT_BATCH, zc->nr_zones - idx);
+        int ret;
+
+        /* Nobody waits for the report of a cancelled request */
+        if (!zc->req) {
+            return;
+        }
+
+        ret = blk_co_zone_report(zc->blk, ufs_zone_offset(zc, idx), &n,
+                                 zones);
+        if (ret < 0) {
+            ufs_zbc_fail_errno(zc, ret);
+            return;
+        }
+        if (n == 0) {
+            break;
+        }
+
+        for (i = 0; i < n; i++) {
+            BlockZoneDescriptor *zone = &zones[i];
+            uint8_t *desc = &zc->outbuf[offset];
+
+            if (!ufs_zbc_report_option_match(zone->state, rep_opts)) {
+                continue;
+            }
+
+            if (nr_descs < max_descs) {
+                desc[0] = zone->type;
+                desc[1] = zone->state << 4;
+                stq_be_p(&desc[8], zone->length >> UFS_BLOCK_SIZE_SHIFT);
+                stq_be_p(&desc[16], zone->start >> UFS_BLOCK_SIZE_SHIFT);
+                stq_be_p(&desc[24], zone->wp >> UFS_BLOCK_SIZE_SHIFT);
+                offset += REPORT_ZONES_DESC_SIZE;
+            } else if (partial) {
+                goto out;
+            }
+
+            nr_descs++;
+        }
+        idx += n;
+    }
+
+out:
+    /* Zone list length and maximum LBA */
+    stl_be_p(&zc->outbuf[0], nr_descs * REPORT_ZONES_DESC_SIZE);
+    stq_be_p(&zc->outbuf[8], nr_blocks - 1);
+
+    zc->len = MIN(offset, limit);
+}
+
+static bool ufs_zbc_zone_op_of(uint8_t action, BlockZoneOp *op)
+{
+    switch (action) {
+    case UFS_ZBC_CLOSE_ZONE:
+        *op = BLK_ZO_CLOSE;
+        return true;
+    case UFS_ZBC_FINISH_ZONE:
+        *op = BLK_ZO_FINISH;
+        return true;
+    case UFS_ZBC_OPEN_ZONE:
+        *op = BLK_ZO_OPEN;
+        return true;
+    case UFS_ZBC_RESET_WRITE_POINTER:
+        *op = BLK_ZO_RESET;
+        return true;
+    default:
+        return false;
+    }
+}
+
+/*
+ * Whether a zone action changes a zone in the given state. For the others,
+ * ZBC completes the command without doing anything, for example OPEN ZONE
+ * of a full zone, and so does the ALL bit for the zones that it skips. A
+ * single read-only or offline zone goes to the drive, which fails the action.
+ */
+static bool ufs_zbc_action_applies(uint8_t action, BlockZoneState state,
+                                   bool all)
+{
+    switch (state) {
+    case BLK_ZS_EMPTY:
+        return !all && (action == UFS_ZBC_OPEN_ZONE ||
+                        action == UFS_ZBC_FINISH_ZONE);
+    case BLK_ZS_IOPEN:
+        return !all || action != UFS_ZBC_OPEN_ZONE;
+    case BLK_ZS_EOPEN:
+        return action != UFS_ZBC_OPEN_ZONE;
+    case BLK_ZS_CLOSED:
+        return action != UFS_ZBC_CLOSE_ZONE;
+    case BLK_ZS_FULL:
+        return action == UFS_ZBC_RESET_WRITE_POINTER;
+    case BLK_ZS_RDONLY:
+    case BLK_ZS_OFFLINE:
+        return !all;
+    default:
+        return false;
+    }
+}
+
+/*
+ * A zone action with the ALL bit, other than RESET WRITE POINTER, which the
+ * drive applies to all zones at once. OPEN ZONE opens the zones that are
+ * closed when it starts, and fails without changing anything if they and
+ * the explicitly open zones together exceed the open zone limit. Opening
+ * one can close an implicitly open zone, which must not be opened then.
+ * FINISH ZONE finishes the closed zones last, since the drive needs a free
+ * open zone to finish one.
+ */
+static void coroutine_fn ufs_zbc_zone_action_all(UfsZbcCmd *zc, uint8_t action,
+                                                 BlockZoneOp op)
+{
+    BlockBackend *blk = zc->blk;
+    uint32_t max_open = blk_get_max_open_zones(blk);
+    g_autofree BlockZoneDescriptor *zones = NULL;
+    g_autoptr(GArray) closed = NULL;
+    uint32_t idx, nr_open = 0;
+    unsigned int i, n;
+    int ret;
+
+    zones = g_new(BlockZoneDescriptor, UFS_ZBC_REPORT_BATCH);
+    if (action == UFS_ZBC_OPEN_ZONE || action == UFS_ZBC_FINISH_ZONE) {
+        closed = g_array_new(false, false, sizeof(uint32_t));
+    }
+
+    for (idx = 0; idx < zc->nr_zones; idx += n) {
+        /* The request was cancelled: change no more zones */
+        if (!zc->req) {
+            return;
+        }
+        n = MIN(UFS_ZBC_REPORT_BATCH, zc->nr_zones - idx);
+        ret = blk_co_zone_report(blk, ufs_zone_offset(zc, idx), &n, zones);
+        if (ret < 0) {
+            ufs_zbc_fail_errno(zc, ret);
+            return;
+        }
+        if (n == 0) {
+            break;
+        }
+
+        for (i = 0; i < n; i++) {
+            BlockZoneDescriptor *zone = &zones[i];
+            uint32_t zone_idx = idx + i;
+
+            if (closed && zone->state == BLK_ZS_CLOSED) {
+                g_array_append_val(closed, zone_idx);
+                continue;
+            }
+            if (action == UFS_ZBC_OPEN_ZONE) {
+                nr_open += zone->state == BLK_ZS_EOPEN;
+                continue;
+            }
+            if (!ufs_zbc_action_applies(action, zone->state, true)) {
+                continue;
+            }
+            if (!zc->req) {
+                return;
+            }
+            ret = blk_co_zone_mgmt(blk, op, zone->start, zone->length);
+            if (ret < 0) {
+                trace_ufs_zbc_zone_mgmt_failed(zc->lun, action, zone->start,
+                                               ret);
+                ufs_zbc_fail_errno(zc, ret);
+                return;
+            }
+        }
+    }
+
+    if (!closed) {
+        return;
+    }
+
+    if (action == UFS_ZBC_OPEN_ZONE && max_open &&
+        nr_open + closed->len > max_open) {
+        ufs_zbc_fail(zc, SENSE_CODE(INSUFFICIENT_ZONE_RESOURCES));
+        return;
+    }
+
+    for (i = 0; i < closed->len; i++) {
+        int64_t start = ufs_zone_offset(zc, g_array_index(closed, uint32_t, i));
+        int64_t end = MIN(start + ufs_zone_offset(zc, 1),
+                          (int64_t)zc->nr_blocks << UFS_BLOCK_SIZE_SHIFT);
+
+        if (!zc->req) {
+            return;
+        }
+        ret = blk_co_zone_mgmt(blk, op, start, end - start);
+        if (ret < 0) {
+            trace_ufs_zbc_zone_mgmt_failed(zc->lun, action, start, ret);
+            ufs_zbc_fail_errno(zc, ret);
+            return;
+        }
+    }
+}
+
+static void coroutine_fn ufs_zbc_zone_action(UfsZbcCmd *zc)
+{
+    BlockBackend *blk = zc->blk;
+    uint8_t *cdb = zc->cdb;
+    uint64_t nr_blocks = zc->nr_blocks;
+    uint8_t action = cdb[1] & 0x1f;
+    uint64_t zone_id = ldq_be_p(&cdb[2]);
+    uint16_t zone_count = lduw_be_p(&cdb[12]);
+    bool all = cdb[14] & 0x01;
+    BlockZoneDescriptor zone;
+    unsigned int n = 1;
+    BlockZoneOp op;
+    int ret;
+
+    trace_ufs_zbc_zone_op(zc->lun, action, zone_id, all);
+
+    if (!ufs_zbc_zone_op_of(action, &op)) {
+        ufs_zbc_fail(zc, SENSE_CODE(INVALID_FIELD));
+        return;
+    }
+
+    if (all) {
+        if (action != UFS_ZBC_RESET_WRITE_POINTER) {
+            ufs_zbc_zone_action_all(zc, action, op);
+            return;
+        }
+        ret = blk_co_zone_mgmt(blk, op, 0, nr_blocks << UFS_BLOCK_SIZE_SHIFT);
+        if (ret < 0) {
+            trace_ufs_zbc_zone_mgmt_failed(zc->lun, action, 0, ret);
+            ufs_zbc_fail_errno(zc, ret);
+        }
+        return;
+    }
+
+    /* Operations on a range of zones are not supported */
+    if (zone_count > 1) {
+        ufs_zbc_fail(zc, SENSE_CODE(INVALID_FIELD));
+        return;
+    }
+
+    if (zone_id >= nr_blocks) {
+        ufs_zbc_fail(zc, SENSE_CODE(LBA_OUT_OF_RANGE));
+        return;
+    }
+
+    ret = blk_co_zone_report(blk, zone_id << UFS_BLOCK_SIZE_SHIFT, &n, &zone);
+    if (ret < 0) {
+        ufs_zbc_fail_errno(zc, ret);
+        return;
+    }
+
+    /* The zone ID is the first LBA of a sequential write required zone */
+    if (n != 1 || zone.start != zone_id << UFS_BLOCK_SIZE_SHIFT ||
+        zone.type == BLK_ZT_CONV) {
+        ufs_zbc_fail(zc, SENSE_CODE(INVALID_FIELD));
+        return;
+    }
+
+    if (!ufs_zbc_action_applies(action, zone.state, false) || !zc->req) {
+        return;
+    }
+
+    ret = blk_co_zone_mgmt(blk, op, zone.start, zone.length);
+    if (ret < 0) {
+        trace_ufs_zbc_zone_mgmt_failed(zc->lun, action, zone.start, ret);
+        ufs_zbc_fail_errno(zc, ret);
+    }
+}
+
+static void coroutine_fn ufs_zbc_co(void *opaque)
+{
+    UfsZbcCmd *zc = opaque;
+    UfsRequest *req;
+    uint8_t sense_buf[UFS_SENSE_SIZE] = { 0 };
+    UfsReqResult result = UFS_REQUEST_SUCCESS;
+    uint32_t xfer_len = 0;
+
+    if (zc->cdb[0] == UFS_ZBC_IN) {
+        ufs_zbc_report_zones(zc);
+    } else {
+        ufs_zbc_zone_action(zc);
+    }
+
+    req = zc->req;
+    if (req) {
+        /*
+         * The coroutine may resume outside the controller's MMIO and BH
+         * handlers. Engage its reentrancy guard, so that a PRDT that points
+         * at the controller's registers cannot reset it under this request.
+         */
+        MemReentrancyGuard *guard = &req->hc->dev->mem_reentrancy_guard;
+        bool engaged = guard->engaged_in_io;
+
+        guard->engaged_in_io = true;
+        req->zbc_cmd = NULL;
+
+        if (zc->status == CHECK_CONDITION) {
+            scsi_build_sense(sense_buf, zc->sense);
+        } else if (zc->status == GOOD) {
+            xfer_len = MIN(zc->len, req->data_len);
+        }
+
+        if (xfer_len > 0 &&
+            dma_buf_read(zc->outbuf, xfer_len, NULL, req->sg,
+                         MEMTXATTRS_UNSPECIFIED) != MEMTX_OK) {
+            result = UFS_REQUEST_FAIL;
+        } else {
+            ufs_build_scsi_response_upiu(req, sense_buf, sizeof(sense_buf),
+                                         xfer_len, zc->status);
+        }
+        ufs_complete_req(req, result);
+        guard->engaged_in_io = engaged;
+    }
+
+    /* The LU may be gone, so this can drop the last reference */
+    blk_co_unref(zc->blk);
+    g_free(zc->outbuf);
+    g_free(zc);
+}
+
+/*
+ * A cancelled request is cleared or completed by the caller. The command
+ * runs on, but leaves the request alone, and changes no more zones. A zone
+ * action already sent to the drive may still complete.
+ */
+void ufs_zbc_cancel(UfsRequest *req)
+{
+    if (req->zbc_cmd) {
+        req->zbc_cmd->req = NULL;
+        req->zbc_cmd = NULL;
+    }
+}
+
+static void ufs_zbc_start(UfsLu *lu, UfsRequest *req, uint8_t *outbuf,
+                          uint32_t outbuf_len)
+{
+    UfsZbcCmd *zc = g_new0(UfsZbcCmd, 1);
+
+    zc->blk = lu->scsi_dev->conf.blk;
+    blk_ref(zc->blk);
+    zc->lun = lu->lun;
+    zc->nr_blocks = be64_to_cpu(lu->unit_desc.logical_block_count);
+    zc->zone_size = lu->zone_size;
+    zc->nr_zones = lu->nr_zones;
+    zc->req = req;
+    memcpy(zc->cdb, req->req_upiu.sc.cdb, UFS_CDB_SIZE);
+    zc->outbuf = outbuf;
+    zc->outbuf_len = outbuf_len;
+    zc->status = GOOD;
+    req->zbc_cmd = zc;
+
+    qemu_coroutine_enter(qemu_coroutine_create(ufs_zbc_co, zc));
+}
+
+/*
+ * Commands that a zoned LU handles itself, which return true with the result
+ * of the request. Everything else, including READ, WRITE, MODE SENSE and the
+ * INQUIRY data that ufs_zoned_fixup_inquiry() adjusts, goes to the wrapped
+ * scsi-hd. Writes reach the drive through it, and the drive checks them
+ * against its zones. scsi-hd reports the zone errors with their sense codes.
+ */
+static bool ufs_emulate_zbc_cmd(UfsLu *lu, UfsRequest *req,
+                                UfsReqResult *result)
+{
+    g_autofree uint8_t *outbuf = NULL;
+    uint8_t *cdb = req->req_upiu.sc.cdb;
+    uint8_t sense_buf[UFS_SENSE_SIZE];
+    uint8_t scsi_status = GOOD;
+    uint32_t len = 0, xfer_len;
+    SCSISense sense;
+
+    /*
+     * Let scsi-hd report a pending unit attention first, as it does for
+     * every command it does not exempt (INQUIRY and REPORT LUNS among them),
+     * so that no zone changes before the guest has seen it.
+     */
+    if (cdb[0] != INQUIRY &&
+        (lu->scsi_dev->unit_attention.key == UNIT_ATTENTION ||
+         lu->bus.unit_attention.key == UNIT_ATTENTION)) {
+        return false;
+    }
+
+    switch (cdb[0]) {
+    case UFS_ZBC_IN: {
+        uint32_t alloc_len = ldl_be_p(&cdb[10]);
+        uint64_t report_len = REPORT_ZONES_HEADER_SIZE +
+                              (uint64_t)REPORT_ZONES_DESC_SIZE * lu->nr_zones;
+        uint32_t outbuf_len;
+
+        /* As for the commands that reach scsi-hd, the PRDT must hold it */
+        if (!ufs_fit_data_buffer(req, alloc_len)) {
+            *result = UFS_REQUEST_MISMATCH_DATA_BUF;
+            return true;
+        }
+
+        /*
+         * Size the buffer by what can be returned, not by alloc_len alone:
+         * at most 64 bytes for each zone of the LU, plus the header.
+         */
+        outbuf_len = MIN(alloc_len, report_len);
+        outbuf_len = MAX(outbuf_len, REPORT_ZONES_HEADER_SIZE);
+        outbuf = g_try_malloc0(outbuf_len);
+        if (!outbuf) {
+            sense = SENSE_CODE(INSUFFICIENT_RESOURCES);
+            scsi_status = CHECK_CONDITION;
+            break;
+        }
+        ufs_zbc_start(lu, req, g_steal_pointer(&outbuf), outbuf_len);
+        *result = UFS_REQUEST_NO_COMPLETE;
+        return true;
+    }
+    case UFS_ZBC_OUT:
+        ufs_zbc_start(lu, req, NULL, 0);
+        *result = UFS_REQUEST_NO_COMPLETE;
+        return true;
+    case INQUIRY:
+        /* Only the ZBC device characteristics VPD page is emulated here */
+        if (!(cdb[1] & 0x1) || cdb[2] != 0xb6) {
+            return false;
+        }
+        if (!ufs_fit_data_buffer(req, lduw_be_p(&cdb[3]))) {
+            *result = UFS_REQUEST_MISMATCH_DATA_BUF;
+            return true;
+        }
+        outbuf = g_malloc0(ZBC_VPD_B6_LEN);
+        len = MIN(ufs_emulate_zbc_vpd_page(lu, outbuf), lduw_be_p(&cdb[3]));
+        break;
+    case WRITE_SAME_10:
+    case WRITE_SAME_16:
+        /*
+         * Not a UFS command (Linux sets no_write_same for UFS), and scsi-hd
+         * turns one with NDOB set or a zero block into write-zeroes, which
+         * the image does not check against the zones.
+         */
+        sense = SENSE_CODE(INVALID_OPCODE);
+        scsi_status = CHECK_CONDITION;
+        break;
+    default:
+        return false;
+    }
+
+    if (scsi_status != GOOD) {
+        scsi_build_sense(sense_buf, sense);
+        len = 0;
+    }
+
+    xfer_len = MIN(len, req->data_len);
+    if (xfer_len > 0 &&
+        dma_buf_read(outbuf, xfer_len, NULL, req->sg,
+                     MEMTXATTRS_UNSPECIFIED) != MEMTX_OK) {
+        *result = UFS_REQUEST_FAIL;
+        return true;
+    }
+
+    ufs_build_scsi_response_upiu(req, sense_buf, sizeof(sense_buf), xfer_len,
+                                 scsi_status);
+
+    *result = UFS_REQUEST_SUCCESS;
+    return true;
+}
+
 static UfsReqResult ufs_emulate_scsi_cmd(UfsLu *lu, UfsRequest *req)
 {
     uint8_t lun = lu->lun;
@@ -411,6 +1142,14 @@ static UfsReqResult ufs_process_scsi_cmd(UfsLu *lu, UfsRequest *req)
     SCSIRequest *scsi_req;
     uint32_t len;
 
+    if (lu->zoned) {
+        UfsReqResult result;
+
+        if (ufs_emulate_zbc_cmd(lu, req, &result)) {
+            return result;
+        }
+    }
+
     /*
      * Each ufs-lu has its own independent virtual SCSI bus. Therefore, we can't
      * use scsi_target_emulate_report_luns() which gets all lu information over
@@ -437,15 +1176,15 @@ static UfsReqResult ufs_process_scsi_cmd(UfsLu *lu, UfsRequest *req)
 
     /*
      * scsi-hd moves as many bytes as the SG list holds, and without an SG
-     * list it would call the transfer_data callback, which ufs-lu does not
-     * set. A UFS device moves what the CDB asks for, so fit the PRDT to the
-     * transfer length, and fail a request whose PRDT describes less, a
-     * missing PRDT included, with OCS MISMATCH DATA BUFFER SIZE, as
-     * virtio-scsi fails a buffer that does not match the command. The
-     * response reports the rest of the Expected Data Transfer Length as a
-     * residual. A request that reports a pending unit attention moves no
-     * data; its sense is already set, so let it through and the guest sees
-     * the UA.
+     * list it would call the transfer_data callback, which only handles the
+     * INQUIRY and READ CAPACITY(16) data of a zoned LU. A UFS device moves
+     * what the CDB asks for, so fit the PRDT to the transfer length, and
+     * fail a request whose PRDT describes less, a missing PRDT included,
+     * with OCS MISMATCH DATA BUFFER SIZE, as virtio-scsi fails a buffer
+     * that does not match the command. The response reports the rest of the
+     * Expected Data Transfer Length as a residual. A request that reports a
+     * pending unit attention moves no data; its sense is already set, so
+     * let it through and the guest sees the UA.
      */
     if (!scsi_req->sense_len &&
         !ufs_fit_data_buffer(req, scsi_req->cmd.xfer)) {
@@ -498,12 +1237,137 @@ void ufs_init_wlu(UfsLu *wlu, uint8_t wlun)
     wlu->scsi_op = &ufs_emulate_scsi_cmd;
 }
 
+/*
+ * Check every zone of the drive and return the number of its sequential
+ * zones, or -1 with errp set. ZBC has no zone capacity: a sequential zone
+ * whose capacity is below its length would need gap zones, which are not
+ * modelled.
+ */
+static int64_t ufs_lu_check_zones(BlockBackend *blk, uint64_t nr_zones,
+                                  Error **errp)
+{
+    g_autofree BlockZoneDescriptor *zones =
+        g_new(BlockZoneDescriptor, UFS_ZBC_REPORT_BATCH);
+    int64_t zone_bytes = blk_get_zone_size(blk);
+    uint64_t idx = 0;
+    int64_t nr_seq = 0;
+
+    while (idx < nr_zones) {
+        unsigned int i, n = MIN(UFS_ZBC_REPORT_BATCH, nr_zones - idx);
+        int ret = blk_zone_report(blk, idx * zone_bytes, &n, zones);
+
+        if (ret < 0) {
+            error_setg_errno(errp, -ret, "cannot report the zones of the "
+                             "drive");
+            return -1;
+        }
+        if (n == 0) {
+            break;
+        }
+        for (i = 0; i < n; i++) {
+            if (zones[i].type == BLK_ZT_CONV) {
+                continue;
+            }
+            if (zones[i].cap != zones[i].length) {
+                error_setg(errp, "the zone at offset %" PRIu64 " of the "
+                           "drive has a capacity (%" PRIu64 ") below its "
+                           "length (%" PRIu64 ")", zones[i].start,
+                           zones[i].cap, zones[i].length);
+                return -1;
+            }
+            nr_seq++;
+        }
+        idx += n;
+    }
+    return nr_seq;
+}
+
+/*
+ * A logical unit on a host-managed zoned drive is a zoned LU. Its zones are
+ * those of the drive, whose geometry must fit the 4 KiB logical blocks.
+ */
+static bool ufs_lu_init_zoned(UfsLu *lu, Error **errp)
+{
+    ERRP_GUARD();
+    BlockBackend *blk = lu->conf.blk;
+    uint64_t nr_blocks = be64_to_cpu(lu->unit_desc.logical_block_count);
+    uint64_t zone_size = blk_get_zone_size(blk);
+    BlockConf conf = lu->conf;
+    uint64_t nr_zones;
+    int64_t nr_seq;
+
+    switch (blk_get_zone_model(blk)) {
+    case BLK_Z_NONE:
+    case BLK_Z_HA:
+        /* A host-aware drive takes any write, so it is a regular LU */
+        return true;
+    case BLK_Z_HM:
+        break;
+    default:
+        g_assert_not_reached();
+    }
+
+    if (!blk_supports_write_perm(blk)) {
+        error_setg(errp, "a zoned logical unit needs a writable drive");
+        return false;
+    }
+
+    if (blk_getlength(blk) % UFS_BLOCK_SIZE) {
+        error_setg(errp, "the size of a zoned drive must be a multiple of %d "
+                   "bytes", UFS_BLOCK_SIZE);
+        return false;
+    }
+
+    conf.logical_block_size = UFS_BLOCK_SIZE;
+    conf.physical_block_size = UFS_BLOCK_SIZE;
+    if (!blkconf_check_zoned_geometry(&conf, errp)) {
+        return false;
+    }
+
+    zone_size /= UFS_BLOCK_SIZE;
+    nr_zones = DIV_ROUND_UP(nr_blocks, zone_size);
+
+    /* The REPORT ZONES zone list length must fit in 32 bits */
+    if (nr_zones > (UINT32_MAX - REPORT_ZONES_HEADER_SIZE) /
+                   REPORT_ZONES_DESC_SIZE) {
+        error_setg(errp, "the drive has too many zones (%" PRIu64 ")",
+                   nr_zones);
+        return false;
+    }
+
+    nr_seq = ufs_lu_check_zones(blk, nr_zones, errp);
+    if (nr_seq < 0) {
+        return false;
+    }
+
+    /*
+     * ZBC cannot report an active zone limit, so the guest could not keep
+     * to one. A limit of at least the number of sequential zones never
+     * binds.
+     */
+    if (blk_get_max_active_zones(blk) &&
+        blk_get_max_active_zones(blk) < nr_seq) {
+        error_setg(errp, "the drive has an active zone limit (%" PRIu32
+                   ") below its %" PRId64 " sequential zones, which ZBC "
+                   "cannot report", blk_get_max_active_zones(blk), nr_seq);
+        error_append_hint(errp, "Use no active zone limit, or one of at "
+                          "least %" PRId64 ".\n", nr_seq);
+        return false;
+    }
+
+    lu->zone_size = zone_size;
+    lu->nr_zones = nr_zones;
+    lu->zoned = true;
+    return true;
+}
+
 static void ufs_init_lu(UfsLu *lu)
 {
     BlockBackend *blk = lu->conf.blk;
     int64_t brdv_len = blk_getlength(blk);
 
     memset(&lu->unit_desc, 0, sizeof(lu->unit_desc));
+    lu->zoned = false;
     lu->unit_desc.length = sizeof(UnitDescriptor);
     lu->unit_desc.descriptor_idn = UFS_QUERY_DESC_IDN_UNIT;
     lu->unit_desc.lu_enable = 0x01;
@@ -591,6 +1455,10 @@ static void ufs_lu_realize(DeviceState *dev, Error **errp)
     }
 
     ufs_init_lu(lu);
+    if (!ufs_lu_init_zoned(lu, errp)) {
+        return;
+    }
+
     if (!ufs_add_lu(u, lu, errp)) {
         return;
     }
diff --git a/hw/ufs/trace-events b/hw/ufs/trace-events
index 17acbebd30..640d30c072 100644
--- a/hw/ufs/trace-events
+++ b/hw/ufs/trace-events
@@ -61,3 +61,8 @@ ufs_err_mcq_delete_cq_sq_not_deleted(uint8_t sqid, uint8_t cqid) "mcq sq %"PRIu8
 # HID (Host Initiated Defragmentation)
 ufs_hid_defrag_operation(uint8_t op, uint8_t state) "HID defrag operation 0x%"PRIx8", new state 0x%"PRIx8""
 ufs_hid_defrag_progress(uint32_t remaining, uint8_t progress) "HID defrag remaining %"PRIu32", progress %"PRIu8"%%"
+
+# lu.c (zoned logical units)
+ufs_zbc_report_zones(uint8_t lun, uint64_t lba, uint32_t alloc_len, uint8_t options) "lun 0x%"PRIx8", lba %"PRIu64", alloc_len %"PRIu32", options 0x%"PRIx8""
+ufs_zbc_zone_op(uint8_t lun, uint8_t action, uint64_t zone_id, bool all) "lun 0x%"PRIx8", action 0x%"PRIx8", zone id %"PRIu64", all %d"
+ufs_zbc_zone_mgmt_failed(uint8_t lun, uint8_t action, uint64_t offset, int ret) "lun 0x%"PRIx8", action 0x%"PRIx8", offset %"PRIu64", ret %d"
diff --git a/hw/ufs/ufs.c b/hw/ufs/ufs.c
index 3de67831ea..f0a59e783e 100644
--- a/hw/ufs/ufs.c
+++ b/hw/ufs/ufs.c
@@ -956,6 +956,19 @@ static void ufs_hce_reset(UfsHc *u)
         }
     }
 
+    /*
+     * Detach the zone commands of zoned LUs from their requests first: the
+     * purge below drains the drives, which can run them on.
+     */
+    for (i = 0; i < u->params.nutrs; i++) {
+        ufs_zbc_cancel(&u->req_list[i]);
+    }
+    for (i = 0; i < ARRAY_SIZE(u->sq); i++) {
+        for (int j = 0; u->sq[i] && j < u->sq[i]->size; j++) {
+            ufs_zbc_cancel(&u->sq[i]->req[j]);
+        }
+    }
+
     /* 2. Purge outstanding SCSI requests for all logical units */
     for (i = 0; i < UFS_MAX_LUS; i++) {
         if (u->lus[i] && u->lus[i]->scsi_dev) {
@@ -1090,6 +1103,7 @@ static void ufs_process_tmr(UfsHc *u, uint32_t val)
                             req->sreq = NULL;
                             scsi_req_cancel(sreq);
                         }
+                        ufs_zbc_cancel(req);
                         req->state = UFS_REQUEST_ERROR;
                     } else {
                         ufs_clear_req(req);
@@ -1346,6 +1360,7 @@ static void ufs_mcq_sq_cleanup(UfsHc *u, uint8_t qid)
                 req->sreq = NULL;
                 scsi_req_cancel(sreq);
             }
+            ufs_zbc_cancel(req);
             req->utrd.header.dword_2 = cpu_to_le32(
                 (le32_to_cpu(req->utrd.header.dword_2) & ~UFS_MASK_OCS) |
                 UFS_OCS_ABORTED);
@@ -2694,6 +2709,7 @@ static void ufs_clear_req(UfsRequest *req)
         req->sreq = NULL;
         scsi_req_cancel(sreq);
     }
+    ufs_zbc_cancel(req);
 
     if (req->sg != NULL) {
         qemu_sglist_destroy(req->sg);
diff --git a/hw/ufs/ufs.h b/hw/ufs/ufs.h
index 0014978322..cb6ab2ab86 100644
--- a/hw/ufs/ufs.h
+++ b/hw/ufs/ufs.h
@@ -66,6 +66,9 @@ typedef struct UfsRequest {
     QEMUSGList *sg;
     uint32_t data_len;
 
+    /* ZBC IN or ZBC OUT command of a zoned LU in progress */
+    struct UfsZbcCmd *zbc_cmd;
+
     /* for MCQ */
     struct UfsSq *sq;
     struct UfsCqEntry cqe;
@@ -88,6 +91,10 @@ typedef struct UfsLu {
     SCSIDevice *scsi_dev;
     BlockConf conf;
     UfsScsiOp scsi_op;
+    /* For Zoned UFS: the zones of the drive, in logical blocks */
+    bool zoned;
+    uint64_t zone_size;
+    uint32_t nr_zones;
 } UfsLu;
 
 /*
@@ -334,6 +341,7 @@ void ufs_build_upiu_header(UfsRequest *req, uint8_t trans_type, uint8_t flags,
 void ufs_build_query_response(UfsRequest *req);
 void ufs_complete_req(UfsRequest *req, UfsReqResult req_result);
 bool ufs_fit_data_buffer(UfsRequest *req, uint64_t len);
+void ufs_zbc_cancel(UfsRequest *req);
 void ufs_wb_update_avail_buffer(UfsHc *u);
 void ufs_init_wlu(UfsLu *wlu, uint8_t wlun);
 bool ufs_realize(UfsHc *u, DeviceState *dev, AddressSpace *dma_as,
diff --git a/include/block/ufs.h b/include/block/ufs.h
index f4a3371bce..b78032e926 100644
--- a/include/block/ufs.h
+++ b/include/block/ufs.h
@@ -708,6 +708,21 @@ enum {
     UFS_MASK_OCS = 0xFF,
 };
 
+/* ZBC IN and ZBC OUT operation codes and their service actions */
+#define UFS_ZBC_OUT 0x94
+#define UFS_ZBC_IN 0x95
+
+enum {
+    UFS_ZBC_REPORT_ZONES = 0x00,
+};
+
+enum {
+    UFS_ZBC_CLOSE_ZONE = 0x01,
+    UFS_ZBC_FINISH_ZONE = 0x02,
+    UFS_ZBC_OPEN_ZONE = 0x03,
+    UFS_ZBC_RESET_WRITE_POINTER = 0x04,
+};
+
 /*
  * struct UfshcdSgEntry - UFSHCI PRD Entry
  * @addr: Physical address; DW-0 and DW-1.

-- 
2.43.0

