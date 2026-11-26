From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 11:02:13 +0900
Subject: [PATCH v4 5/5] tests/qtest: Add tests for Zoned UFS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-zoned-ufs-v4b-v4-5-f90239d12a55@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795658529; l=71970;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=FfE6S7z1qxuNF4BBCvZGjES7zOq5m6rrE0wfGNViedU=;
 b=nWYfd+++5jSRxX8K/GoscTBEVjPMA6MWSIT918lozrv89v731WERazofEuR+Y7V5+MYfg+orL
 dQMcdyKdaqmAT15a4hFnzfAfItgF/4UDFZFSL0ekTpHvH6E0O033vgV
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add qtests for zoned logical units on zoned qcow2 images, skipped
without qemu-img. Besides the ZBC commands, six tests hold FINISH ALL
on a throttle node. They cancel it, or send REPORT ZONES whose PRDT
points at a controller register.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 tests/qtest/ufs-test.c | 1587 ++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 1587 insertions(+)

diff --git a/tests/qtest/ufs-test.c b/tests/qtest/ufs-test.c
index 1f86d834ac..767eece79a 100644
--- a/tests/qtest/ufs-test.c
+++ b/tests/qtest/ufs-test.c
@@ -2863,6 +2863,1554 @@ static void ufs_test_fault_injection_legacy(void *obj, void *data,
     ufs_exit(ufs, alloc);
 }
 
+#define ZONE_SIZE (2 * 1024 * 1024)
+#define ZONE_BLOCKS (ZONE_SIZE / 4096)
+#define MAX_OPEN_ZONE 6
+#define NUM_ZONES (TEST_IMAGE_SIZE / ZONE_SIZE)
+#define REPORT_ZONES_DESC_SIZE 64
+#define ZONED_TEST_LUN 2
+/* A second zoned LU whose capacity is not a multiple of the zone size */
+#define ODD_ZONED_TEST_LUN 3
+#define ODD_ZONE_SIZE (4 * 1024 * 1024)
+#define ODD_TEST_SIZE (TEST_IMAGE_SIZE - 2 * 1024 * 1024)
+#define ODD_NUM_ZONES DIV_ROUND_UP(ODD_TEST_SIZE, ODD_ZONE_SIZE)
+/* A zoned LU of more than 8 TiB with 128 MiB zones, for LBAs of 2^31 and up */
+#define BIG_ZONED_TEST_LUN 5
+#define BIG_ZONE_SIZE (128 * 1024 * 1024)
+#define BIG_ZONED_TEST_SIZE ((8ULL << 40) + BIG_ZONE_SIZE)
+/* A zoned LU whose first zones are conventional */
+#define CONV_ZONED_TEST_LUN 6
+#define CONV_NUM_CONV_ZONES 2
+/*
+ * A zoned LU whose image sits on a throttle node, to hold a zone action in
+ * flight. The throttle group runs on the realtime clock, since it is created
+ * before the qtest accelerator: a held I/O ends in real time or on a drain.
+ */
+#define SLOW_ZONED_TEST_LUN 7
+
+/* Whether ufs_zufs_test_setup() could add the zoned LUs */
+static bool zufs_have_images;
+
+static void ufs_zufs_build_write16(uint8_t *cdb, uint64_t lba, uint32_t blocks)
+{
+    memset(cdb, 0, UFS_CDB_SIZE);
+    cdb[0] = WRITE_16;
+    stq_be_p(&cdb[2], lba);
+    stl_be_p(&cdb[10], blocks);
+}
+
+static void ufs_zufs_build_zbc_out(uint8_t *cdb, uint8_t action, uint64_t lba,
+                                   bool all)
+{
+    memset(cdb, 0, UFS_CDB_SIZE);
+    cdb[0] = UFS_ZBC_OUT;
+    cdb[1] = action;
+    stq_be_p(&cdb[2], lba);
+    cdb[14] = all ? 0x01 : 0x00;
+}
+
+static void ufs_zufs_build_report_zones(uint8_t *cdb, uint8_t rep_opts,
+                                        uint32_t alloc_len)
+{
+    memset(cdb, 0, UFS_CDB_SIZE);
+    cdb[0] = UFS_ZBC_IN;
+    cdb[1] = UFS_ZBC_REPORT_ZONES;
+    stl_be_p(&cdb[10], alloc_len);
+    cdb[14] = rep_opts;
+}
+
+static void ufs_zufs_clear_unit_attention(QUfs *ufs)
+{
+    const uint8_t request_sense_cdb[UFS_CDB_SIZE] = {
+        REQUEST_SENSE,
+    };
+    uint8_t buf[4096];
+    UtpUpiuRsp rsp_upiu;
+    enum UtpOcsCodes ocs;
+
+    ocs = ufs_send_scsi_command(ufs, ZONED_TEST_LUN, request_sense_cdb, NULL, 0,
+                                buf, sizeof(buf), &rsp_upiu);
+    g_assert_cmpuint(ocs, ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, CHECK_CONDITION);
+}
+
+static uint8_t ufs_zufs_send(QUfs *ufs, const uint8_t *cdb,
+                             const uint8_t *data_in, size_t data_in_len,
+                             uint8_t *data_out, size_t data_out_len,
+                             UtpUpiuRsp *rsp_upiu)
+{
+    enum UtpOcsCodes ocs;
+
+    ocs = ufs_send_scsi_command(ufs, ZONED_TEST_LUN, cdb, data_in, data_in_len,
+                                data_out, data_out_len, rsp_upiu);
+    g_assert_cmpuint(ocs, ==, UFS_OCS_SUCCESS);
+    return rsp_upiu->header.scsi_status;
+}
+
+static void ufs_zufs_assert_sense(UtpUpiuRsp *rsp_upiu, uint8_t key,
+                                  uint8_t asc, uint8_t ascq)
+{
+    g_assert_cmpuint(rsp_upiu->header.scsi_status, ==, CHECK_CONDITION);
+    g_assert_cmpuint(rsp_upiu->sr.sense_data[2] & 0xf, ==, key);
+    g_assert_cmpuint(rsp_upiu->sr.sense_data[12], ==, asc);
+    g_assert_cmpuint(rsp_upiu->sr.sense_data[13], ==, ascq);
+}
+
+static uint32_t ufs_zufs_count_zones(QUfs *ufs, uint8_t rep_opts)
+{
+    uint8_t buf[4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+
+    ufs_zufs_build_report_zones(cdb, rep_opts, sizeof(buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    return ldl_be_p(&buf[0]) / REPORT_ZONES_DESC_SIZE;
+}
+
+/* Condition and write pointer of the zone at zone_start */
+static uint8_t ufs_zufs_zone(QUfs *ufs, uint8_t lun, uint64_t zone_start,
+                             uint64_t *wp)
+{
+    uint8_t buf[4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    enum UtpOcsCodes ocs;
+
+    ufs_zufs_build_report_zones(cdb, 0x00, sizeof(buf));
+    stq_be_p(&cdb[2], zone_start);
+    ocs = ufs_send_scsi_command(ufs, lun, cdb, NULL, 0, buf, sizeof(buf),
+                                &rsp_upiu);
+    g_assert_cmpuint(ocs, ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    g_assert_cmpuint(ldq_be_p(&buf[64 + 16]), ==, zone_start);
+    *wp = ldq_be_p(&buf[64 + 24]);
+    return buf[64 + 1] >> 4;
+}
+
+static uint64_t ufs_zufs_write_pointer(QUfs *ufs, uint64_t zone_start)
+{
+    uint64_t wp;
+
+    ufs_zufs_zone(ufs, ZONED_TEST_LUN, zone_start, &wp);
+    return wp;
+}
+
+static uint8_t ufs_zufs_zone_cond(QUfs *ufs, uint64_t zone_start)
+{
+    uint64_t wp;
+
+    return ufs_zufs_zone(ufs, ZONED_TEST_LUN, zone_start, &wp);
+}
+
+static void ufstest_zufs_init(void *obj, void *data, QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint8_t buf[4096] = { 0 };
+    const uint8_t inquiry_cdb[UFS_CDB_SIZE] = {
+        INQUIRY, 0x00, 0x00, 0x00, 0x60,
+    };
+    const uint8_t inquiry_vpd_00_cdb[UFS_CDB_SIZE] = {
+        INQUIRY, 0x01 /* EVPD */, 0x00 /* page code */, 0x00, 0x40,
+    };
+    const uint8_t inquiry_vpd_b6_cdb[UFS_CDB_SIZE] = {
+        INQUIRY, 0x01 /* EVPD */, 0xb6 /* page code */, 0x00, 0x40,
+    };
+    const uint8_t mode_sense_caching_cdb[UFS_CDB_SIZE] = {
+        MODE_SENSE_10, 0x08 /* DBD */, MODE_PAGE_CACHING, 0x00, 0x00,
+        0x00, 0x00, 0x00, 0xff,
+    };
+    const uint8_t read_capacity_cdb[UFS_CDB_SIZE] = {
+        SERVICE_ACTION_IN_16, SAI_READ_CAPACITY_16, 0x00, 0x00, 0x00, 0x00,
+        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20,
+    };
+    uint8_t report_zones_cdb[UFS_CDB_SIZE];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    uint32_t zone_list_len;
+    uint8_t vpd_00_len;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_clear_unit_attention(ufs);
+
+    /* Standard INQUIRY: host-managed zoned block device */
+    g_assert_cmpuint(ufs_zufs_send(ufs, inquiry_cdb, NULL, 0, buf, 0x60,
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[0] & 0x1f, ==, TYPE_ZBC);
+
+    /* Supported VPD pages include the ZBC device characteristics page */
+    g_assert_cmpuint(ufs_zufs_send(ufs, inquiry_vpd_00_cdb, NULL, 0, buf, 0x40,
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[0], ==, TYPE_ZBC);
+    g_assert_nonnull(memchr(&buf[4], 0xb6, buf[3]));
+    g_assert_cmpuint(buf[4 + buf[3] - 1], ==, 0xb6);
+    vpd_00_len = buf[3];
+
+    /* ZBC device characteristics VPD page */
+    g_assert_cmpuint(ufs_zufs_send(ufs, inquiry_vpd_b6_cdb, NULL, 0, buf, 0x40,
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[0], ==, TYPE_ZBC);
+    g_assert_cmpuint(buf[1], ==, 0xb6);
+    g_assert_cmpuint(lduw_be_p(&buf[2]), ==, 0x3c);
+    /* URSWRZ */
+    g_assert_cmpuint(buf[4] & 0x1, ==, 1);
+    g_assert_cmpuint(ldl_be_p(&buf[16]), ==, MAX_OPEN_ZONE);
+
+    /* Allocation length 4: only the header, whose page length counts 0xb6 */
+    memset(cdb, 0, sizeof(cdb));
+    memcpy(cdb, inquiry_vpd_00_cdb, 5);
+    cdb[4] = 4;
+    memset(buf, 0, sizeof(buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[0], ==, TYPE_ZBC);
+    g_assert_cmpuint(buf[3], ==, vpd_00_len);
+    g_assert_cmpuint(buf[4], ==, 0);
+
+    /* Allocation length of the scsi-hd list: 0xb6 does not fit */
+    cdb[4] = 4 + vpd_00_len - 1;
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[3], ==, vpd_00_len);
+    g_assert_cmpuint(buf[4 + vpd_00_len - 2], !=, 0xb6);
+    g_assert_cmpuint(buf[4 + vpd_00_len - 2], !=, 0);
+    g_assert_cmpuint(buf[4 + vpd_00_len - 1], ==, 0);
+
+    /* WRITE SAME is not advertised in the Block Limits and LBP pages */
+    cdb[2] = 0xb0;
+    cdb[4] = 0x40;
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[0], ==, TYPE_ZBC);
+    g_assert_cmpuint(ldq_be_p(&buf[36]), ==, 0);
+    cdb[2] = 0xb2;
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    /* LBPU set, LBPWS and LBPWS10 clear */
+    g_assert_cmpuint(buf[5] & 0xe0, ==, 0x80);
+
+    /*
+     * An INQUIRY without a PRDT fails like on a regular LU, also for the page
+     * that ufs-lu answers itself
+     */
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, ZONED_TEST_LUN, inquiry_cdb,
+                                           NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     UFS_OCS_MISMATCH_DATA_BUF_SIZE);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, ZONED_TEST_LUN,
+                                           inquiry_vpd_b6_cdb, NULL, 0, NULL,
+                                           0, &rsp_upiu), ==,
+                     UFS_OCS_MISMATCH_DATA_BUF_SIZE);
+
+    /* Logical block provisioning as on a regular LU: LBPME */
+    g_assert_cmpuint(ufs_zufs_send(ufs, read_capacity_cdb, NULL, 0, buf,
+                                   sizeof(buf), &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[14] & 0x80, ==, 0x80);
+    /* RC BASIS 1: the returned LBA is the last one of the LU */
+    g_assert_cmpuint(buf[12] & 0x30, ==, 0x10);
+    g_assert_cmpuint(ldq_be_p(&buf[0]), ==, TEST_IMAGE_SIZE / 4096 - 1);
+
+    /* MODE SENSE takes the scsi-hd disk path: caching page, WCE and DPOFUA */
+    g_assert_cmpuint(ufs_zufs_send(ufs, mode_sense_caching_cdb, NULL, 0, buf,
+                                   0xff, &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(buf[3] & 0x10, ==, 0x10);
+    g_assert_cmpuint(buf[8] & 0x3f, ==, MODE_PAGE_CACHING);
+    g_assert_cmpuint(buf[10] & 0x04, ==, 0x04);
+
+    /* Report zones */
+    ufs_zufs_build_report_zones(report_zones_cdb, 0x00, sizeof(buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, report_zones_cdb, NULL, 0, buf,
+                                   sizeof(buf), &rsp_upiu), ==, GOOD);
+    zone_list_len = ldl_be_p(&buf[0]);
+    g_assert_cmpuint(zone_list_len, ==, REPORT_ZONES_DESC_SIZE * NUM_ZONES);
+    g_assert_cmpuint(ldq_be_p(&buf[8]), ==, TEST_IMAGE_SIZE / 4096 - 1);
+    /* First zone: sequential write required, empty */
+    g_assert_cmpuint(buf[64] & 0xf, ==, 0x2);
+    g_assert_cmpuint(buf[65] >> 4, ==, 0x1);
+    g_assert_cmpuint(ldq_be_p(&buf[64 + 8]), ==, ZONE_BLOCKS);
+
+    ufs_exit(ufs, alloc);
+}
+
+static void ufstest_zufs_write(void *obj, void *data, QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint8_t read_buf[4096] = { 0 };
+    uint8_t write_buf[4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    int i;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_clear_unit_attention(ufs);
+    memset(write_buf, 0xab, sizeof(write_buf));
+
+    /* Write at the write pointer of zone 0 */
+    ufs_zufs_build_write16(cdb, 0, 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+
+    /* Unaligned write error */
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, CHECK_CONDITION);
+    g_assert_cmpint(rsp_upiu.sr.sense_data[12], ==, 0x21);
+    g_assert_cmpint(rsp_upiu.sr.sense_data[13], ==, 0x04);
+
+    /* Linux flushes zoned disks with SYNCHRONIZE CACHE(16) */
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = SYNCHRONIZE_CACHE_16;
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+
+    /* Zone 0 is implicitly open */
+    ufs_zufs_build_report_zones(cdb, 0x02, sizeof(read_buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, read_buf,
+                                   sizeof(read_buf), &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&read_buf[0]), ==, REPORT_ZONES_DESC_SIZE);
+    g_assert_cmpuint(ldq_be_p(&read_buf[64 + 24]), ==, 1);
+
+    /* Resetting an open zone empties it */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_RESET_WRITE_POINTER, 0, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    ufs_zufs_build_write16(cdb, 0, 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+
+    /*
+     * Writing to one zone more than MAX_OPEN_ZONE closes an implicitly open
+     * zone instead of failing.
+     */
+    for (i = 1; i <= MAX_OPEN_ZONE; i++) {
+        ufs_zufs_build_write16(cdb, (uint64_t)i * ZONE_BLOCKS, 1);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                       NULL, 0, &rsp_upiu), ==, GOOD);
+    }
+    ufs_zufs_build_report_zones(cdb, 0x04, sizeof(read_buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, read_buf,
+                                   sizeof(read_buf), &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&read_buf[0]), ==, REPORT_ZONES_DESC_SIZE);
+
+    /* Finishing an empty zone makes it full */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE,
+                           (uint64_t)(NUM_ZONES - 1) * ZONE_BLOCKS, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    ufs_zufs_build_report_zones(cdb, 0x05, sizeof(read_buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, read_buf,
+                                   sizeof(read_buf), &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&read_buf[0]), ==, REPORT_ZONES_DESC_SIZE);
+
+    /* Write and zone management beyond the last LBA: LBA OUT OF RANGE */
+    ufs_zufs_build_write16(cdb, TEST_IMAGE_SIZE / 4096, 1);
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x00);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, TEST_IMAGE_SIZE / 4096,
+                           false);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x00);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_RESET_WRITE_POINTER,
+                           TEST_IMAGE_SIZE / 4096, false);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x00);
+    ufs_zufs_build_report_zones(cdb, 0x00, sizeof(read_buf));
+    stq_be_p(&cdb[2], TEST_IMAGE_SIZE / 4096);
+    ufs_zufs_send(ufs, cdb, NULL, 0, read_buf, sizeof(read_buf), &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x00);
+
+    /* Unknown reporting option and zone operation: INVALID FIELD IN CDB */
+    ufs_zufs_build_report_zones(cdb, 0x08, sizeof(read_buf));
+    ufs_zufs_send(ufs, cdb, NULL, 0, read_buf, sizeof(read_buf), &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+    ufs_zufs_build_zbc_out(cdb, 0x05, 0, false);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+
+    /* An allocation length above the data buffer fails like a short PRDT */
+    ufs_zufs_build_report_zones(cdb, 0x00, 1024 * 1024);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, ZONED_TEST_LUN, cdb, NULL, 0,
+                                           read_buf, 256, &rsp_upiu), ==,
+                     UFS_OCS_MISMATCH_DATA_BUF_SIZE);
+
+    /* Reset all zones */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_RESET_WRITE_POINTER, 0, true);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    ufs_zufs_build_report_zones(cdb, 0x01, sizeof(read_buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, read_buf,
+                                   sizeof(read_buf), &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&read_buf[0]), ==,
+                     REPORT_ZONES_DESC_SIZE * NUM_ZONES);
+
+    ufs_exit(ufs, alloc);
+}
+
+static void ufstest_zufs_write_cmds(void *obj, void *data,
+                                   QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint8_t fill_buf[8 * 4096] = { 0 };
+    uint64_t lba;
+    uint32_t blocks;
+    uint8_t read_buf[4096];
+    uint8_t write_buf[4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    const uint64_t zone1 = ZONE_BLOCKS, zone2 = 2 * ZONE_BLOCKS,
+                   zone3 = 3 * ZONE_BLOCKS;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_clear_unit_attention(ufs);
+    memset(write_buf, 0xcd, sizeof(write_buf));
+
+    /* WRITE(10) and WRITE(6) move the write pointer like WRITE(16) */
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = WRITE_10;
+    stl_be_p(&cdb[2], 0);
+    stw_be_p(&cdb[7], 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, 0), ==, 1);
+
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = WRITE_6;
+    cdb[1] = (zone3 >> 16) & 0x1f;
+    cdb[2] = (zone3 >> 8) & 0xff;
+    cdb[3] = zone3 & 0xff;
+    cdb[4] = 1;
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone3), ==, zone3 + 1);
+
+    /* WRITE SAME at the write pointer: INVALID COMMAND OPERATION CODE */
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = WRITE_SAME_16;
+    stq_be_p(&cdb[2], 1);
+    stl_be_p(&cdb[10], 2);
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x20, 0x00);
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = WRITE_SAME_10;
+    stl_be_p(&cdb[2], 1);
+    stw_be_p(&cdb[7], 2);
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x20, 0x00);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, 0), ==, 1);
+
+    /*
+     * A write at the write pointer crossing the end of its zone: the drive
+     * fails it, and scsi-hd reports WRITE BOUNDARY VIOLATION
+     */
+    for (lba = zone1; lba < zone2 - 1; lba += blocks) {
+        blocks = MIN(8, zone2 - 1 - lba);
+        ufs_zufs_build_write16(cdb, lba, blocks);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, fill_buf, blocks * 4096,
+                                       NULL, 0, &rsp_upiu), ==, GOOD);
+    }
+    ufs_zufs_build_write16(cdb, zone2 - 1, 2);
+    ufs_zufs_send(ufs, cdb, fill_buf, 2 * 4096, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x05);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone1), ==, zone2 - 1);
+
+    /* A write to a full zone fails with INVALID FIELD IN CDB */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, zone2, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    ufs_zufs_build_write16(cdb, zone2, 1);
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+
+    /* A WRITE(10) at an LBA above 2^31 is checked like a WRITE(16) */
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = REQUEST_SENSE;
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, BIG_ZONED_TEST_LUN, cdb, NULL,
+                                           0, read_buf, sizeof(read_buf),
+                                           &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    cdb[0] = WRITE_10;
+    stl_be_p(&cdb[2], 0x80000001);
+    stw_be_p(&cdb[7], 1);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, BIG_ZONED_TEST_LUN, cdb,
+                                           write_buf, sizeof(write_buf), NULL,
+                                           0, &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x04);
+    /* ... and one at the zone start moves that zone's write pointer */
+    stl_be_p(&cdb[2], 0x80000000);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, BIG_ZONED_TEST_LUN, cdb,
+                                           write_buf, sizeof(write_buf), NULL,
+                                           0, &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    ufs_zufs_build_report_zones(cdb, 0x00, sizeof(read_buf));
+    stq_be_p(&cdb[2], 0x80000000);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, BIG_ZONED_TEST_LUN, cdb, NULL,
+                                           0, read_buf, sizeof(read_buf),
+                                           &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    g_assert_cmpuint(ldq_be_p(&read_buf[64 + 16]), ==, 0x80000000);
+    g_assert_cmpuint(ldq_be_p(&read_buf[64 + 24]), ==, 0x80000001);
+
+    ufs_exit(ufs, alloc);
+}
+
+static void ufstest_zufs_open_zones(void *obj, void *data,
+                                    QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint8_t write_buf[4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    int i;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_clear_unit_attention(ufs);
+    memset(write_buf, 0xef, sizeof(write_buf));
+
+    /* Open MAX_OPEN_ZONE zones explicitly */
+    for (i = 0; i < MAX_OPEN_ZONE; i++) {
+        ufs_zufs_build_zbc_out(cdb, UFS_ZBC_OPEN_ZONE,
+                               (uint64_t)i * ZONE_BLOCKS, false);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu),
+                         ==, GOOD);
+    }
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x03), ==, MAX_OPEN_ZONE);
+
+    /* No implicitly open zone to close: INSUFFICIENT ZONE RESOURCES */
+    ufs_zufs_build_write16(cdb, (uint64_t)MAX_OPEN_ZONE * ZONE_BLOCKS, 1);
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, DATA_PROTECT, 0x55, 0x0e);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_OPEN_ZONE,
+                           (uint64_t)MAX_OPEN_ZONE * ZONE_BLOCKS, false);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, DATA_PROTECT, 0x55, 0x0e);
+
+    /* Closing an open zone with nothing written empties it */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_CLOSE_ZONE, 0, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x01), ==, NUM_ZONES - 5);
+
+    /*
+     * Fill the freed resource with an implicitly open zone, then write to
+     * one more zone: the implicitly open zone is closed.
+     */
+    ufs_zufs_build_write16(cdb, (uint64_t)MAX_OPEN_ZONE * ZONE_BLOCKS, 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    ufs_zufs_build_write16(cdb, (uint64_t)(MAX_OPEN_ZONE + 1) * ZONE_BLOCKS,
+                           1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x04), ==, 1);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x02), ==, 1);
+
+    /* OPEN ALL: 5 explicit + 1 closed fit, the implicit one is closed */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_OPEN_ZONE, 0, true);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x03), ==, MAX_OPEN_ZONE);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x04), ==, 1);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x02), ==, 0);
+
+    /* OPEN ALL again: 6 explicit + 1 closed do not fit, nothing changes */
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, DATA_PROTECT, 0x55, 0x0e);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x04), ==, 1);
+
+    /* FINISH ALL fills open and closed zones, empty ones stay empty */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, 0, true);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x05), ==, MAX_OPEN_ZONE + 1);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x01), ==,
+                     NUM_ZONES - MAX_OPEN_ZONE - 1);
+
+    /* RESET ALL */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_RESET_WRITE_POINTER, 0, true);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x01), ==, NUM_ZONES);
+
+    /*
+     * FINISH ALL finishes a closed zone in front of explicitly open zones
+     * that fill the open zone limit
+     */
+    ufs_zufs_build_write16(cdb, 0, 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_CLOSE_ZONE, 0, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    for (i = 1; i <= MAX_OPEN_ZONE; i++) {
+        ufs_zufs_build_zbc_out(cdb, UFS_ZBC_OPEN_ZONE,
+                               (uint64_t)i * ZONE_BLOCKS, false);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu),
+                         ==, GOOD);
+    }
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, 0, true);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x05), ==, MAX_OPEN_ZONE + 1);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_RESET_WRITE_POINTER, 0, true);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+
+    /*
+     * OPEN ALL that cannot open every closed zone opens none. The seventh
+     * write closes zone 0, CLOSE ZONE closes zone 1, and zones 2 to 6 are
+     * opened explicitly.
+     */
+    for (i = 0; i <= MAX_OPEN_ZONE; i++) {
+        ufs_zufs_build_write16(cdb, (uint64_t)i * ZONE_BLOCKS, 1);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                       NULL, 0, &rsp_upiu), ==, GOOD);
+    }
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_CLOSE_ZONE, ZONE_BLOCKS, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    for (i = 2; i <= MAX_OPEN_ZONE; i++) {
+        ufs_zufs_build_zbc_out(cdb, UFS_ZBC_OPEN_ZONE,
+                               (uint64_t)i * ZONE_BLOCKS, false);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu),
+                         ==, GOOD);
+    }
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x04), ==, 2);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_OPEN_ZONE, 0, true);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, DATA_PROTECT, 0x55, 0x0e);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x04), ==, 2);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x03), ==, MAX_OPEN_ZONE - 1);
+
+    ufs_exit(ufs, alloc);
+}
+
+static void ufstest_zufs_unit_attention(void *obj, void *data,
+                                        QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint8_t write_buf[4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    memset(write_buf, 0x5a, sizeof(write_buf));
+
+    /*
+     * After the reset in ufs_init(), the first command that scsi-hd does not
+     * exempt gets UNIT ATTENTION and is not performed, zone commands too:
+     * the zone stays empty and the write pointer stays put, so that the
+     * guest can retry.
+     */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, 0, false);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, CHECK_CONDITION);
+    g_assert_cmpuint(rsp_upiu.sr.sense_data[2] & 0xf, ==, UNIT_ATTENTION);
+    ufs_zufs_build_write16(cdb, 0, 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, 0), ==, 1);
+
+    ufs_exit(ufs, alloc);
+}
+
+static void ufstest_zufs_report_zones(void *obj, void *data,
+                                      QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    const uint8_t request_sense_cdb[UFS_CDB_SIZE] = {
+        REQUEST_SENSE,
+    };
+    uint8_t buf[4096];
+    uint8_t write_buf[4096];
+    uint8_t write_buf2[2 * 4096] = { 0 };
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    uint64_t last_start;
+    enum UtpOcsCodes ocs;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_clear_unit_attention(ufs);
+    memset(write_buf, 0x3c, sizeof(write_buf));
+
+    /* A start LBA inside a zone reports from that zone on */
+    ufs_zufs_build_report_zones(cdb, 0x00, sizeof(buf));
+    stq_be_p(&cdb[2], 2 * ZONE_BLOCKS + 5);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&buf[0]), ==,
+                     (NUM_ZONES - 2) * REPORT_ZONES_DESC_SIZE);
+    g_assert_cmpuint(ldq_be_p(&buf[64 + 16]), ==, 2 * ZONE_BLOCKS);
+
+    /* PARTIAL: the zone list length counts only the returned zones */
+    ufs_zufs_build_report_zones(cdb, 0x80, 64 + 3 * REPORT_ZONES_DESC_SIZE);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&buf[0]), ==, 3 * REPORT_ZONES_DESC_SIZE);
+    ufs_zufs_build_report_zones(cdb, 0x00, 64 + 3 * REPORT_ZONES_DESC_SIZE);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, buf, sizeof(buf),
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&buf[0]), ==, NUM_ZONES * REPORT_ZONES_DESC_SIZE);
+
+    /* All zones except gap zones. None is read-only or conventional */
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x3e), ==, NUM_ZONES);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x06), ==, 0);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x3f), ==, 0);
+
+    /* A capacity that is not a multiple of the zone size: a smaller zone */
+    ocs = ufs_send_scsi_command(ufs, ODD_ZONED_TEST_LUN, request_sense_cdb,
+                                NULL, 0, buf, sizeof(buf), &rsp_upiu);
+    g_assert_cmpuint(ocs, ==, UFS_OCS_SUCCESS);
+    last_start = (uint64_t)(ODD_NUM_ZONES - 1) * (ODD_ZONE_SIZE / 4096);
+    ufs_zufs_build_report_zones(cdb, 0x00, sizeof(buf));
+    stq_be_p(&cdb[2], last_start);
+    ocs = ufs_send_scsi_command(ufs, ODD_ZONED_TEST_LUN, cdb, NULL, 0, buf,
+                                sizeof(buf), &rsp_upiu);
+    g_assert_cmpuint(ocs, ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&buf[0]), ==, REPORT_ZONES_DESC_SIZE);
+    g_assert_cmpuint(ldq_be_p(&buf[64 + 8]), ==,
+                     ODD_TEST_SIZE / 4096 - last_start);
+
+    /* A write crossing the end of that zone and of the logical unit */
+    ufs_zufs_build_write16(cdb, last_start, 1);
+    ocs = ufs_send_scsi_command(ufs, ODD_ZONED_TEST_LUN, cdb, write_buf,
+                                sizeof(write_buf), NULL, 0, &rsp_upiu);
+    g_assert_cmpuint(ocs, ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    ufs_zufs_build_write16(cdb, ODD_TEST_SIZE / 4096 - 1, 2);
+    ocs = ufs_send_scsi_command(ufs, ODD_ZONED_TEST_LUN, cdb, write_buf2,
+                                sizeof(write_buf2), NULL, 0, &rsp_upiu);
+    g_assert_cmpuint(ocs, ==, UFS_OCS_SUCCESS);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x00);
+
+    ufs_exit(ufs, alloc);
+}
+
+/* A zoned LU whose first zones are conventional, as the drive reports them */
+static void ufstest_zufs_conv_zones(void *obj, void *data,
+                                    QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    const uint64_t conv_end = CONV_NUM_CONV_ZONES * ZONE_BLOCKS;
+    uint8_t two_blocks[2 * 4096] = { 0 };
+    const uint8_t request_sense_cdb[UFS_CDB_SIZE] = {
+        REQUEST_SENSE,
+    };
+    uint8_t buf[4096];
+    uint8_t write_buf[4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    uint64_t wp;
+    int i;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN,
+                                           request_sense_cdb, NULL, 0, buf,
+                                           sizeof(buf), &rsp_upiu), ==,
+                     UFS_OCS_SUCCESS);
+    memset(write_buf, 0xab, sizeof(write_buf));
+
+    /* Conventional zones: type 1, condition NOT WRITE POINTER */
+    ufs_zufs_build_report_zones(cdb, 0x3f, sizeof(buf));
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN, cdb, NULL,
+                                           0, buf, sizeof(buf), &rsp_upiu), ==,
+                     UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    g_assert_cmpuint(ldl_be_p(&buf[0]), ==,
+                     CONV_NUM_CONV_ZONES * REPORT_ZONES_DESC_SIZE);
+    for (i = 0; i < CONV_NUM_CONV_ZONES; i++) {
+        uint8_t *desc = &buf[64 + i * REPORT_ZONES_DESC_SIZE];
+
+        g_assert_cmpuint(desc[0] & 0xf, ==, 0x1);
+        g_assert_cmpuint(desc[1] >> 4, ==, 0x0);
+        g_assert_cmpuint(ldq_be_p(&desc[16]), ==, i * ZONE_BLOCKS);
+    }
+    g_assert_cmpuint(ufs_zufs_zone(ufs, CONV_ZONED_TEST_LUN, conv_end, &wp),
+                     ==, 0x1);
+
+    /* A conventional zone takes writes anywhere, in any order */
+    for (i = 0; i < 2; i++) {
+        ufs_zufs_build_write16(cdb, i ? 7 : conv_end - 1, 1);
+        g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN, cdb,
+                                               write_buf, sizeof(write_buf),
+                                               NULL, 0, &rsp_upiu), ==,
+                         UFS_OCS_SUCCESS);
+        g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    }
+
+    /* A write from a conventional into a sequential zone */
+    ufs_zufs_build_write16(cdb, conv_end - 1, 2);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN, cdb,
+                                           two_blocks, sizeof(two_blocks),
+                                           NULL, 0, &rsp_upiu),
+                     ==, UFS_OCS_SUCCESS);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x05);
+
+    /* Zone actions do not apply to conventional zones */
+    for (i = UFS_ZBC_CLOSE_ZONE; i <= UFS_ZBC_RESET_WRITE_POINTER; i++) {
+        ufs_zufs_build_zbc_out(cdb, i, ZONE_BLOCKS, false);
+        g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN, cdb,
+                                               NULL, 0, NULL, 0, &rsp_upiu),
+                         ==, UFS_OCS_SUCCESS);
+        ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+    }
+
+    /* ... but the ALL bit skips them, and resets the sequential zones */
+    ufs_zufs_build_write16(cdb, conv_end, 1);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN, cdb,
+                                           write_buf, sizeof(write_buf), NULL,
+                                           0, &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    g_assert_cmpuint(ufs_zufs_zone(ufs, CONV_ZONED_TEST_LUN, conv_end, &wp),
+                     ==, 0x2);
+    for (i = UFS_ZBC_CLOSE_ZONE; i <= UFS_ZBC_RESET_WRITE_POINTER; i++) {
+        ufs_zufs_build_zbc_out(cdb, i, 0, true);
+        g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN, cdb,
+                                               NULL, 0, NULL, 0, &rsp_upiu),
+                         ==, UFS_OCS_SUCCESS);
+        g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    }
+    g_assert_cmpuint(ufs_zufs_zone(ufs, CONV_ZONED_TEST_LUN, conv_end, &wp),
+                     ==, 0x1);
+    g_assert_cmpuint(wp, ==, conv_end);
+
+    /* The data of a conventional zone stays */
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = READ_10;
+    stl_be_p(&cdb[2], 7);
+    stw_be_p(&cdb[7], 1);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, CONV_ZONED_TEST_LUN, cdb, NULL,
+                                           0, buf, sizeof(buf), &rsp_upiu), ==,
+                     UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    g_assert_cmpmem(buf, sizeof(buf), write_buf, sizeof(write_buf));
+
+    ufs_exit(ufs, alloc);
+}
+
+static void ufstest_zufs_more_cmds(void *obj, void *data,
+                                   QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint8_t write_buf[4096];
+    uint8_t fill_buf[8 * 4096];
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    const uint64_t zone4 = 4 * ZONE_BLOCKS, zone5 = 5 * ZONE_BLOCKS,
+                   zone6 = 6 * ZONE_BLOCKS, zone7 = 7 * ZONE_BLOCKS;
+    uint64_t lba;
+    uint32_t blocks;
+    int i;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_clear_unit_attention(ufs);
+    memset(write_buf, 0x96, sizeof(write_buf));
+    memset(fill_buf, 0x69, sizeof(fill_buf));
+
+    /* WRITE(12) and WRITE AND VERIFY(16) move the write pointer */
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = WRITE_12;
+    stl_be_p(&cdb[2], zone4);
+    stl_be_p(&cdb[6], 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = WRITE_VERIFY_16;
+    stq_be_p(&cdb[2], zone4 + 1);
+    stl_be_p(&cdb[10], 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone4), ==, zone4 + 2);
+
+    /* CLOSE ALL closes it, FINISH ZONE fills the closed zone */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_CLOSE_ZONE, 0, true);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x04), ==, 1);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, zone4, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x05), ==, 1);
+
+    /* OPEN, CLOSE and FINISH ZONE leave the full zone alone */
+    for (i = UFS_ZBC_CLOSE_ZONE; i <= UFS_ZBC_OPEN_ZONE; i++) {
+        ufs_zufs_build_zbc_out(cdb, i, zone4, false);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu),
+                         ==, GOOD);
+        g_assert_cmpuint(ufs_zufs_zone_cond(ufs, zone4), ==, 0xe);
+    }
+
+    /* A zone operation on a range of zones is not supported */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, zone5, false);
+    stw_be_p(&cdb[12], 2);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+
+    /* With the ALL bit, ZONE COUNT does not matter */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_CLOSE_ZONE, 0, true);
+    stw_be_p(&cdb[12], 2);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+
+    /* A zone ID that is not the start of a zone */
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_RESET_WRITE_POINTER, zone5 + 1, false);
+    ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+
+    /*
+     * A write without a PRDT, or with one shorter than the transfer, fails
+     * and leaves the write pointer alone
+     */
+    ufs_zufs_build_write16(cdb, zone5, 1);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, ZONED_TEST_LUN, cdb, NULL, 0,
+                                           NULL, 0, &rsp_upiu), ==,
+                     UFS_OCS_MISMATCH_DATA_BUF_SIZE);
+    ufs_zufs_build_write16(cdb, zone5, 2);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, ZONED_TEST_LUN, cdb, write_buf,
+                                           sizeof(write_buf), NULL, 0,
+                                           &rsp_upiu), ==,
+                     UFS_OCS_MISMATCH_DATA_BUF_SIZE);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone5), ==, zone5);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x02), ==, 0);
+
+    /*
+     * UNMAP of a whole cluster below the write pointer drops the data and
+     * leaves the zone condition and the write pointer alone. A write below
+     * the write pointer still fails.
+     */
+    for (i = 0; i < 2; i++) {
+        ufs_zufs_build_write16(cdb, zone5 + i * 8, 8);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, fill_buf, sizeof(fill_buf),
+                                       NULL, 0, &rsp_upiu), ==, GOOD);
+    }
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = UNMAP;
+    stw_be_p(&cdb[7], 24);
+    memset(write_buf, 0, 24);
+    stw_be_p(&write_buf[0], 22);
+    stw_be_p(&write_buf[2], 16);
+    stq_be_p(&write_buf[8], zone5);
+    stl_be_p(&write_buf[16], 16);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, 24, NULL, 0,
+                                   &rsp_upiu), ==, GOOD);
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = READ_16;
+    stq_be_p(&cdb[2], zone5);
+    stl_be_p(&cdb[10], 1);
+    memset(write_buf, 0x96, sizeof(write_buf));
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, write_buf,
+                                   sizeof(write_buf), &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(write_buf[0], ==, 0);
+    g_assert_cmpuint(ufs_zufs_zone_cond(ufs, zone5), ==, 0x2);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone5), ==, zone5 + 16);
+    ufs_zufs_build_write16(cdb, zone5, 1);
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x21, 0x04);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_RESET_WRITE_POINTER, zone5, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    memset(write_buf, 0x96, sizeof(write_buf));
+
+    /*
+     * A write whose PRDT is shorter than the write changes no zone: a closed
+     * zone stays closed, an explicitly open one stays open.
+     */
+    ufs_zufs_build_write16(cdb, zone6, 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                   NULL, 0, &rsp_upiu), ==, GOOD);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_CLOSE_ZONE, zone6, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    ufs_zufs_build_write16(cdb, zone6 + 1, 2);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, ZONED_TEST_LUN, cdb, write_buf,
+                                           sizeof(write_buf), NULL, 0,
+                                           &rsp_upiu), ==,
+                     UFS_OCS_MISMATCH_DATA_BUF_SIZE);
+    g_assert_cmpuint(ufs_zufs_zone_cond(ufs, zone6), ==, 0x4);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone6), ==, zone6 + 1);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x02), ==, 0);
+
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_OPEN_ZONE, zone7, false);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     GOOD);
+    ufs_zufs_build_write16(cdb, zone7, ZONE_BLOCKS);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, ZONED_TEST_LUN, cdb, write_buf,
+                                           sizeof(write_buf), NULL, 0,
+                                           &rsp_upiu), ==,
+                     UFS_OCS_MISMATCH_DATA_BUF_SIZE);
+    g_assert_cmpuint(ufs_zufs_zone_cond(ufs, zone7), ==, 0x3);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone7), ==, zone7);
+
+    /*
+     * Nor does a write that scsi-hd rejects, here for its WRPROTECT field:
+     * the closed zone stays closed, the explicitly open one that the write
+     * would fill stays open, and no implicitly open zone is closed to make
+     * room for the zone of the write.
+     */
+    ufs_zufs_build_write16(cdb, zone6 + 1, 1);
+    cdb[1] = 0x20;
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+    /* A read that follows does not start the rejected write either */
+    memset(cdb, 0, sizeof(cdb));
+    cdb[0] = READ_16;
+    stq_be_p(&cdb[2], zone6);
+    stl_be_p(&cdb[10], 1);
+    g_assert_cmpuint(ufs_zufs_send(ufs, cdb, NULL, 0, fill_buf, 4096,
+                                   &rsp_upiu), ==, GOOD);
+    g_assert_cmpuint(ufs_zufs_zone_cond(ufs, zone6), ==, 0x4);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone6), ==, zone6 + 1);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x02), ==, 0);
+
+    for (lba = zone7; lba < zone7 + ZONE_BLOCKS - 1; lba += blocks) {
+        blocks = MIN(8, zone7 + ZONE_BLOCKS - 1 - lba);
+        ufs_zufs_build_write16(cdb, lba, blocks);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, fill_buf, blocks * 4096, NULL,
+                                       0, &rsp_upiu), ==, GOOD);
+    }
+    ufs_zufs_build_write16(cdb, zone7 + ZONE_BLOCKS - 1, 1);
+    cdb[1] = 0x20;
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+    g_assert_cmpuint(ufs_zufs_zone_cond(ufs, zone7), ==, 0x3);
+    g_assert_cmpuint(ufs_zufs_write_pointer(ufs, zone7), ==,
+                     zone7 + ZONE_BLOCKS - 1);
+
+    for (i = 0; i < MAX_OPEN_ZONE - 1; i++) {
+        ufs_zufs_build_write16(cdb, (8 + i) * ZONE_BLOCKS, 1);
+        g_assert_cmpuint(ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf),
+                                       NULL, 0, &rsp_upiu), ==, GOOD);
+    }
+    ufs_zufs_build_write16(cdb, (8 + i) * ZONE_BLOCKS, 1);
+    cdb[1] = 0x20;
+    ufs_zufs_send(ufs, cdb, write_buf, sizeof(write_buf), NULL, 0, &rsp_upiu);
+    ufs_zufs_assert_sense(&rsp_upiu, ILLEGAL_REQUEST, 0x24, 0x00);
+    g_assert_cmpuint(ufs_zufs_count_zones(ufs, 0x02), ==, MAX_OPEN_ZONE - 1);
+    g_assert_cmpuint(ufs_zufs_zone_cond(ufs, (8 + i) * ZONE_BLOCKS), ==, 0x1);
+
+    ufs_exit(ufs, alloc);
+}
+
+/* Limit the I/O of SLOW_ZONED_TEST_LUN to iops I/Os per second, 0: none */
+static void ufs_zufs_throttle(QUfs *ufs, int iops)
+{
+    qtest_qmp_assert_success(ufs->dev.bus->qts,
+                             "{ 'execute': 'qom-set', 'arguments': {"
+                             " 'path': '/objects/tg0', 'property': 'limits',"
+                             " 'value': { 'iops-total': %d } } }", iops);
+}
+
+/* Submit a command without data to lun, and do not wait for it */
+static int ufs_zufs_submit(QUfs *ufs, uint8_t lun, const uint8_t *cdb)
+{
+    QTestState *qts = ufs->dev.bus->qts;
+    int slot = alloc_cmd_desc_slot(ufs);
+    uint64_t req_upiu_addr =
+        ufs->cmd_desc_addr + slot * UTP_COMMAND_DESCRIPTOR_SIZE;
+    UtpUpiuReq req_upiu = { 0 };
+    UtpTransferReqDesc utrd;
+
+    req_upiu.header.trans_type = UFS_UPIU_TRANSACTION_COMMAND;
+    req_upiu.header.lun = lun;
+    req_upiu.header.task_tag = slot;
+    memcpy(req_upiu.sc.cdb, cdb, UFS_CDB_SIZE);
+    qtest_memwrite(qts, req_upiu_addr, &req_upiu, sizeof(req_upiu));
+
+    utrd = ufs_build_req_utrd(req_upiu_addr, UFS_UTP_NO_DATA_TRANSFER, 0);
+    if (ufs->support_mcq) {
+        __ufs_send_transfer_request_mcq_async(ufs, lun, &utrd);
+    } else {
+        qtest_memwrite(qts,
+                       ufs->utrlba + UTRD_TEST_SLOT * sizeof(utrd), &utrd,
+                       sizeof(utrd));
+        ufs_wreg(ufs, A_UTRLDBR, 1 << UTRD_TEST_SLOT);
+    }
+    return slot;
+}
+
+/*
+ * Open zones 3 to 5 of SLOW_ZONED_TEST_LUN implicitly, throttle its I/O, and
+ * submit FINISH ALL, which then holds on the write pointer of zone 3 for
+ * about a second. Returns the command descriptor slot of FINISH ALL.
+ */
+static int ufs_zufs_hold_finish_all(QUfs *ufs)
+{
+    const uint8_t request_sense_cdb[UFS_CDB_SIZE] = {
+        REQUEST_SENSE,
+    };
+    uint8_t buf[4096] = { 0 };
+    uint8_t cdb[UFS_CDB_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    int i;
+
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, SLOW_ZONED_TEST_LUN,
+                                           request_sense_cdb, NULL, 0, buf,
+                                           sizeof(buf), &rsp_upiu), ==,
+                     UFS_OCS_SUCCESS);
+    for (i = 3; i <= 5; i++) {
+        ufs_zufs_build_write16(cdb, i * ZONE_BLOCKS, 1);
+        g_assert_cmpuint(ufs_send_scsi_command(ufs, SLOW_ZONED_TEST_LUN, cdb,
+                                               buf, sizeof(buf), NULL, 0,
+                                               &rsp_upiu), ==,
+                         UFS_OCS_SUCCESS);
+        g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+    }
+
+    /*
+     * The first I/O after the limit is set passes at once: spend it on
+     * FINISH ZONE of empty zone 1, so that the next one has to wait.
+     */
+    ufs_zufs_throttle(ufs, 1);
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, ZONE_BLOCKS, false);
+    g_assert_cmpuint(ufs_send_scsi_command(ufs, SLOW_ZONED_TEST_LUN, cdb,
+                                           NULL, 0, NULL, 0, &rsp_upiu), ==,
+                     UFS_OCS_SUCCESS);
+    g_assert_cmpuint(rsp_upiu.header.scsi_status, ==, GOOD);
+
+    ufs_zufs_build_zbc_out(cdb, UFS_ZBC_FINISH_ZONE, 0, true);
+    return ufs_zufs_submit(ufs, SLOW_ZONED_TEST_LUN, cdb);
+}
+
+/* Let the held I/O through: stopping the VM drains the drives */
+static void ufs_zufs_wait_hold(QUfs *ufs)
+{
+    qtest_qmp_assert_success(ufs->dev.bus->qts, "{ 'execute': 'stop' }");
+    qtest_qmp_assert_success(ufs->dev.bus->qts, "{ 'execute': 'cont' }");
+}
+
+static uint8_t ufs_zufs_slow_zone_cond(QUfs *ufs, uint64_t zone_start)
+{
+    uint64_t wp;
+
+    return ufs_zufs_zone(ufs, SLOW_ZONED_TEST_LUN, zone_start, &wp);
+}
+
+/*
+ * HCE reset while FINISH ALL is in flight: the reset neither completes the
+ * request nor lets it finish more zones than the one it was finishing.
+ */
+static void ufstest_zufs_hce_reset(void *obj, void *data,
+                                   QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    const uint8_t request_sense_cdb[UFS_CDB_SIZE] = {
+        REQUEST_SENSE,
+    };
+    uint8_t buf[4096];
+    UtpUpiuRsp rsp_upiu;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_hold_finish_all(ufs);
+    ufs_wreg(ufs, A_HCE, 0);
+    g_assert_cmpuint(ufs_rreg(ufs, A_UTRLDBR), ==, 0);
+    ufs_zufs_wait_hold(ufs);
+    ufs_zufs_throttle(ufs, 0);
+
+    ufs_exit(ufs, alloc);
+    ufs_init(ufs, alloc);
+    ufs_send_scsi_command(ufs, SLOW_ZONED_TEST_LUN, request_sense_cdb, NULL,
+                          0, buf, sizeof(buf), &rsp_upiu);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 3 * ZONE_BLOCKS), ==, 0xe);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 4 * ZONE_BLOCKS), ==, 0x2);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 5 * ZONE_BLOCKS), ==, 0x2);
+
+    ufs_exit(ufs, alloc);
+}
+
+/*
+ * REPORT ZONES that waits on the drive behind FINISH ALL, with its PRDT on
+ * the HCE register: the transfer fails instead of resetting the controller
+ * under the request. QEMU warns once about the blocked access.
+ */
+static void ufstest_zufs_report_dma_regs(void *obj, void *data,
+                                         QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    QTestState *qts = ufs->dev.bus->qts;
+    UfshcdSgEntry entry = { 0 };
+    UtpUpiuReq req_upiu = { 0 };
+    UtpTransferReqDesc utrd;
+    UtpUpiuRsp rsp_upiu;
+    uint8_t cdb[UFS_CDB_SIZE];
+    uint64_t req_upiu_addr;
+    int finish_slot, slot;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    finish_slot = ufs_zufs_hold_finish_all(ufs);
+
+    slot = alloc_cmd_desc_slot(ufs);
+    g_assert_cmpint(slot, !=, UTRD_TEST_SLOT);
+    req_upiu_addr = ufs->cmd_desc_addr + slot * UTP_COMMAND_DESCRIPTOR_SIZE;
+    entry.addr = cpu_to_le64(ufs->bar.addr + A_HCE);
+    entry.size = cpu_to_le32(4 - 1);
+    qtest_memwrite(qts, req_upiu_addr + UTP_PRDT_UPIU_OFFSET, &entry,
+                   sizeof(entry));
+    ufs_zufs_build_report_zones(cdb, 0x00, 4);
+    req_upiu.header.trans_type = UFS_UPIU_TRANSACTION_COMMAND;
+    req_upiu.header.flags = UFS_UPIU_CMD_FLAGS_READ;
+    req_upiu.header.lun = SLOW_ZONED_TEST_LUN;
+    req_upiu.header.task_tag = slot;
+    req_upiu.sc.exp_data_transfer_len = cpu_to_be32(4);
+    memcpy(req_upiu.sc.cdb, cdb, UFS_CDB_SIZE);
+    qtest_memwrite(qts, req_upiu_addr, &req_upiu, sizeof(req_upiu));
+    utrd = ufs_build_req_utrd(req_upiu_addr, UFS_UTP_DEVICE_TO_HOST, 1);
+    qtest_memwrite(qts, ufs->utrlba + slot * sizeof(utrd), &utrd,
+                   sizeof(utrd));
+    ufs_wreg(ufs, A_UTRLDBR, 1 << slot);
+
+    /* REPORT ZONES waits on the drive, so it resumes outside the BH */
+    qtest_clock_step(qts, 100);
+    g_assert_cmpuint(ufs_rreg(ufs, A_UTRLDBR) & (1 << slot), !=, 0);
+
+    /* Let REPORT ZONES through, then FINISH ALL to its end */
+    ufs_zufs_wait_hold(ufs);
+    ufs_zufs_throttle(ufs, 0);
+    ufs_zufs_wait_hold(ufs);
+
+    g_assert_cmpuint(ufs_rreg(ufs, A_HCE), ==, 1);
+    g_assert_cmpuint(ufs_rreg(ufs, A_UTRLDBR), ==, 0);
+    qtest_memread(qts, ufs->utrlba + slot * sizeof(utrd), &utrd,
+                  sizeof(utrd));
+    g_assert_cmpuint(le32_to_cpu(utrd.header.dword_2), ==,
+                     UFS_OCS_INVALID_CMD_TABLE_ATTR);
+    release_cmd_desc_slot(ufs, slot);
+    release_cmd_desc_slot(ufs, finish_slot);
+    g_assert_cmpuint(ufs_send_nop_out(ufs, &rsp_upiu), ==, UFS_OCS_SUCCESS);
+
+    ufs_exit(ufs, alloc);
+}
+
+/*
+ * MCQ submission queue cleanup of FINISH ALL in flight: the request
+ * completes once, as aborted, and FINISH ALL stops.
+ */
+static void ufstest_zufs_mcq_cleanup(void *obj, void *data,
+                                     QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint64_t sq;
+    uint32_t cti, rtc;
+    UtpUpiuRsp rsp_upiu;
+    UfsCqEntry cqe;
+    int slot;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    sq = ufs->sqdao[TEST_QID];
+    slot = ufs_zufs_hold_finish_all(ufs);
+
+    ufs_wreg(ufs, sq + A_SQRTC, FIELD_DP32(0, SQRTC, STOP, 1));
+    g_assert_true(FIELD_EX32(ufs_rreg(ufs, sq + A_SQRTS), SQRTS, STS));
+    cti = FIELD_DP32(0, SQCTI, TASK_TAG, slot);
+    cti = FIELD_DP32(cti, SQCTI, LUN, SLOW_ZONED_TEST_LUN);
+    ufs_wreg(ufs, sq + A_SQCTI, cti);
+    rtc = FIELD_DP32(0, SQRTC, STOP, 1);
+    rtc = FIELD_DP32(rtc, SQRTC, ICU, 1);
+    ufs_wreg(ufs, sq + A_SQRTC, rtc);
+    g_assert_cmpuint(FIELD_EX32(ufs_rreg(ufs, sq + A_SQRTS), SQRTS, RTC), ==,
+                     0);
+    g_assert_cmpint(ufs_mcq_poll_cq(ufs, &cqe, 1), ==, 1);
+    g_assert_cmpuint(cqe.status, ==, UFS_OCS_ABORTED);
+    ufs_wreg(ufs, A_IS, FIELD_DP32(0, IS, CQES, 1));
+    release_cmd_desc_slot(ufs, slot);
+
+    /* The held zone action ends, and nothing else completes */
+    ufs_zufs_wait_hold(ufs);
+    g_assert_cmpint(ufs_mcq_poll_cq(ufs, &cqe, 1), ==, 0);
+    ufs_wreg(ufs, sq + A_SQRTC, 0);
+    ufs_zufs_throttle(ufs, 0);
+
+    g_assert_cmpuint(ufs_send_nop_out(ufs, &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 3 * ZONE_BLOCKS), ==, 0xe);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 4 * ZONE_BLOCKS), ==, 0x2);
+
+    ufs_exit(ufs, alloc);
+}
+
+/*
+ * MCQ submission queue cleanup of FINISH ALL in flight while the completion
+ * queue is full: the aborted request waits for room, and FINISH ALL stops.
+ */
+static void ufstest_zufs_mcq_cleanup_cq_full(void *obj, void *data,
+                                             QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    QTestState *qts = ufs->dev.bus->qts;
+    UfsCqEntry cqe[QUEUE_SIZE];
+    UtpUpiuRsp rsp_upiu;
+    uint32_t cti, rtc;
+    uint64_t sq;
+    int i, nop, slot;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    sq = ufs->sqdao[TEST_QID];
+    slot = ufs_zufs_hold_finish_all(ufs);
+
+    /* Fill the completion queue */
+    for (i = 0; i < QUEUE_SIZE - 1; i++) {
+        nop = ufs_mcq_send_nop_out_async(ufs);
+        qtest_clock_step(qts, 100);
+        release_cmd_desc_slot(ufs, nop);
+    }
+
+    ufs_wreg(ufs, sq + A_SQRTC, FIELD_DP32(0, SQRTC, STOP, 1));
+    g_assert_true(FIELD_EX32(ufs_rreg(ufs, sq + A_SQRTS), SQRTS, STS));
+    cti = FIELD_DP32(0, SQCTI, TASK_TAG, slot);
+    cti = FIELD_DP32(cti, SQCTI, LUN, SLOW_ZONED_TEST_LUN);
+    ufs_wreg(ufs, sq + A_SQCTI, cti);
+    rtc = FIELD_DP32(0, SQRTC, STOP, 1);
+    rtc = FIELD_DP32(rtc, SQRTC, ICU, 1);
+    ufs_wreg(ufs, sq + A_SQRTC, rtc);
+    g_assert_cmpuint(FIELD_EX32(ufs_rreg(ufs, sq + A_SQRTS), SQRTS, RTC), ==,
+                     0);
+
+    /* Let the held I/O and any further zone action run to their end */
+    ufs_zufs_wait_hold(ufs);
+    ufs_zufs_throttle(ufs, 0);
+    ufs_zufs_wait_hold(ufs);
+    ufs_zufs_wait_hold(ufs);
+
+    /* The aborted request completes once there is room for it */
+    g_assert_cmpint(ufs_mcq_poll_cq(ufs, cqe, QUEUE_SIZE), ==, QUEUE_SIZE - 1);
+    qtest_clock_step(qts, 100);
+    g_assert_cmpint(ufs_mcq_poll_cq(ufs, cqe, 1), ==, 1);
+    g_assert_cmpuint(cqe[0].status, ==, UFS_OCS_ABORTED);
+    ufs_wreg(ufs, A_IS, FIELD_DP32(0, IS, CQES, 1));
+    release_cmd_desc_slot(ufs, slot);
+    ufs_wreg(ufs, sq + A_SQRTC, 0);
+
+    g_assert_cmpuint(ufs_send_nop_out(ufs, &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 3 * ZONE_BLOCKS), ==, 0xe);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 4 * ZONE_BLOCKS), ==, 0x2);
+
+    ufs_exit(ufs, alloc);
+}
+
+/*
+ * MCQ ABORT TASK of FINISH ALL in flight: FINISH ALL stops at the zone that
+ * it was finishing, and the request completes only through the cleanup of
+ * its submission queue.
+ */
+static void ufstest_zufs_mcq_abort(void *obj, void *data,
+                                   QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    uint64_t sq, utmrlba;
+    UtpTaskReqDesc tmr;
+    uint32_t cti, rtc;
+    UtpUpiuRsp rsp_upiu;
+    UfsCqEntry cqe;
+    int slot;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    utmrlba = guest_alloc(alloc, 8 * sizeof(UtpTaskReqDesc));
+    ufs_wreg(ufs, A_UTMRLBA, utmrlba & 0xffffffff);
+    ufs_wreg(ufs, A_UTMRLBAU, utmrlba >> 32);
+    ufs_wreg(ufs, A_UTMRLRSR, 1);
+    sq = ufs->sqdao[TEST_QID];
+    slot = ufs_zufs_hold_finish_all(ufs);
+
+    ufs_send_tmr(ufs, utmrlba, 0, UFS_ABORT_TASK, SLOW_ZONED_TEST_LUN, slot,
+                 &tmr);
+    g_assert_cmpuint(be32_to_cpu(tmr.upiu_rsp.output_param1), ==,
+                     UFS_UPIU_TASK_MANAGEMENT_FUNC_COMPL);
+    g_assert_cmpint(ufs_mcq_poll_cq(ufs, &cqe, 1), ==, 0);
+
+    /* The held zone action ends, and the aborted request stays pending */
+    ufs_zufs_wait_hold(ufs);
+    g_assert_cmpint(ufs_mcq_poll_cq(ufs, &cqe, 1), ==, 0);
+
+    ufs_wreg(ufs, sq + A_SQRTC, FIELD_DP32(0, SQRTC, STOP, 1));
+    cti = FIELD_DP32(0, SQCTI, TASK_TAG, slot);
+    cti = FIELD_DP32(cti, SQCTI, LUN, SLOW_ZONED_TEST_LUN);
+    ufs_wreg(ufs, sq + A_SQCTI, cti);
+    rtc = FIELD_DP32(0, SQRTC, STOP, 1);
+    rtc = FIELD_DP32(rtc, SQRTC, ICU, 1);
+    ufs_wreg(ufs, sq + A_SQRTC, rtc);
+    g_assert_cmpuint(FIELD_EX32(ufs_rreg(ufs, sq + A_SQRTS), SQRTS, RTC), ==,
+                     0);
+    g_assert_cmpint(ufs_mcq_poll_cq(ufs, &cqe, 1), ==, 1);
+    g_assert_cmpuint(cqe.status, ==, UFS_OCS_ABORTED);
+    ufs_wreg(ufs, A_IS, FIELD_DP32(0, IS, CQES, 1));
+    release_cmd_desc_slot(ufs, slot);
+    ufs_wreg(ufs, sq + A_SQRTC, 0);
+    ufs_zufs_throttle(ufs, 0);
+
+    g_assert_cmpuint(ufs_send_nop_out(ufs, &rsp_upiu), ==, UFS_OCS_SUCCESS);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 3 * ZONE_BLOCKS), ==, 0xe);
+    g_assert_cmpuint(ufs_zufs_slow_zone_cond(ufs, 4 * ZONE_BLOCKS), ==, 0x2);
+
+    guest_free(alloc, utmrlba);
+    ufs_exit(ufs, alloc);
+}
+
+/*
+ * Unplug the controller while FINISH ALL is in flight. The held I/O ends in
+ * real time after the unplug, so that FINISH ALL outlives the LU.
+ */
+static void ufstest_zufs_eject(void *obj, void *data, QGuestAllocator *alloc)
+{
+    QUfs *ufs = obj;
+    QTestState *qts = ufs->dev.bus->qts;
+
+    if (!zufs_have_images) {
+        g_test_skip("QTEST_QEMU_IMG not set or qemu-img missing");
+        return;
+    }
+
+    ufs_init(ufs, alloc);
+    ufs_zufs_hold_finish_all(ufs);
+    qtest_outl(qts, ACPI_PCIHP_ADDR + PCI_EJ_BASE, 1 << 4);
+    qtest_qmp_assert_success(qts, "{ 'execute': 'query-status' }");
+    g_usleep(3 * G_USEC_PER_SEC);
+    qtest_qmp_assert_success(qts, "{ 'execute': 'query-status' }");
+}
+
+/* Create a host-managed zoned qcow2 image with qemu-img, or NULL without it */
+static char *ufs_zufs_create_image(uint64_t size, uint32_t zone_size,
+                                   const char *opts)
+{
+    g_autofree char *rpath = NULL;
+    g_autofree char *cli = NULL;
+    char *img_path;
+    GError *err = NULL;
+    int fd, rc;
+
+    if (!have_qemu_img()) {
+        return NULL;
+    }
+    rpath = realpath(getenv("QTEST_QEMU_IMG"), NULL);
+
+    fd = g_file_open_tmp("qtest-ufs-zoned.XXXXXX", &img_path, NULL);
+    g_assert(fd >= 0);
+    close(fd);
+
+    cli = g_strdup_printf("%s create -q -f qcow2 -o size=%" PRIu64 ","
+                          "zone.mode=host-managed,zone.size=%" PRIu32 ","
+                          "zone.capacity=%" PRIu32 "%s%s %s",
+                          rpath, size, zone_size, zone_size, opts ? "," : "",
+                          opts ? opts : "", img_path);
+    g_assert_true(g_spawn_command_line_sync(cli, NULL, NULL, &rc, &err));
+    g_assert_true(g_spawn_check_exit_status(rc, &err));
+
+    g_test_queue_destroy(drive_destroy, img_path);
+    return img_path;
+}
+
+static void *ufs_zufs_test_setup(GString *cmd_line, void *arg)
+{
+    g_autofree char *zoned_opts =
+        g_strdup_printf("zone.max_open_zones=%d", MAX_OPEN_ZONE);
+    g_autofree char *conv_opts =
+        g_strdup_printf("zone.conventional_zones=%d", CONV_NUM_CONV_ZONES);
+    const struct {
+        uint8_t lun;
+        uint64_t size;
+        uint32_t zone_size;
+        const char *opts;
+    } lus[] = {
+        { ZONED_TEST_LUN, TEST_IMAGE_SIZE, ZONE_SIZE, zoned_opts },
+        { ODD_ZONED_TEST_LUN, ODD_TEST_SIZE, ODD_ZONE_SIZE, NULL },
+        { BIG_ZONED_TEST_LUN, BIG_ZONED_TEST_SIZE, BIG_ZONE_SIZE, NULL },
+        { CONV_ZONED_TEST_LUN, TEST_IMAGE_SIZE, ZONE_SIZE, conv_opts },
+    };
+    char *paths[ARRAY_SIZE(lus)];
+    char *slow_path;
+    int i;
+
+    zufs_have_images = false;
+    for (i = 0; i < ARRAY_SIZE(lus); i++) {
+        paths[i] = ufs_zufs_create_image(lus[i].size, lus[i].zone_size,
+                                         lus[i].opts);
+        if (!paths[i]) {
+            return arg;
+        }
+    }
+
+    for (i = 0; i < ARRAY_SIZE(lus); i++) {
+        g_string_append_printf(cmd_line,
+                               " -blockdev qcow2,node-name=zdrv%d,"
+                               "discard=unmap,file.driver=file,"
+                               "file.filename=%s "
+                               "-device ufs-lu,bus=ufs0,drive=zdrv%d,lun=%d",
+                               lus[i].lun, paths[i], lus[i].lun, lus[i].lun);
+    }
+
+    slow_path = ufs_zufs_create_image(TEST_IMAGE_SIZE, ZONE_SIZE, NULL);
+    g_string_append_printf(cmd_line,
+                           " -object throttle-group,id=tg0 "
+                           "-blockdev file,node-name=zfile,filename=%s "
+                           "-blockdev throttle,node-name=zthrottle,"
+                           "throttle-group=tg0,file=zfile "
+                           "-blockdev qcow2,node-name=zslow,file=zthrottle "
+                           "-device ufs-lu,bus=ufs0,drive=zslow,lun=%d",
+                           slow_path, SLOW_ZONED_TEST_LUN);
+    zufs_have_images = true;
+
+    return arg;
+}
+
 static void ufs_register_nodes(void)
 {
     const char *arch;
@@ -2885,7 +4433,18 @@ static void ufs_register_nodes(void)
                                              "mcq=false,nutrs=32,nutmrs=8,"
                                              "wb-max-size=1024,"
                                              "wb-min-size=256" };
+    QOSGraphTestOptions zufs_test_opts = { .before = ufs_zufs_test_setup,
+                                           .edge.extra_device_opts =
+                                               "mcq=false,nutrs=32,nutmrs=8" };
+    QOSGraphTestOptions zufs_mcq_test_opts = { .before = ufs_zufs_test_setup,
+                                               .edge.extra_device_opts =
+                                                   "mcq=true,mcq-maxq=1" };
     QOSGraphTestOptions acpi_eject_test_opts = { .subprocess = true };
+    QOSGraphTestOptions zufs_eject_test_opts = {
+        .before = ufs_zufs_test_setup,
+        .subprocess = true,
+        .edge.extra_device_opts = "mcq=false,nutrs=32,nutmrs=8",
+    };
 
     add_qpci_address(&edge_opts, &(QPCIAddress){ .devfn = QPCI_DEVFN(4, 0) });
 
@@ -2907,6 +4466,8 @@ static void ufs_register_nodes(void)
     if (!strcmp(arch, "i386") || !strcmp(arch, "x86_64")) {
         qos_add_test("acpi-eject", "ufs", ufstest_acpi_eject,
                      &acpi_eject_test_opts);
+        qos_add_test("zufs-eject", "ufs", ufstest_zufs_eject,
+                     &zufs_eject_test_opts);
     }
     qos_add_test("init", "ufs", ufstest_init, NULL);
     qos_add_test("legacy-read-write", "ufs", ufstest_read_write, &io_test_opts);
@@ -2932,6 +4493,32 @@ static void ufs_register_nodes(void)
     qos_add_test("wb-init", "ufs", ufstest_wb_init, &wb_test_opts);
     qos_add_test("wb-read-write", "ufs", ufstest_wb_read_write, &wb_test_opts);
     qos_add_test("hid", "ufs", ufstest_hid, &io_test_opts);
+    qos_add_test("zufs-init", "ufs", ufstest_zufs_init, &zufs_test_opts);
+    qos_add_test("zufs-write", "ufs", ufstest_zufs_write, &zufs_test_opts);
+    qos_add_test("zufs-mcq-write", "ufs", ufstest_zufs_write,
+                 &zufs_mcq_test_opts);
+    qos_add_test("zufs-write-cmds", "ufs", ufstest_zufs_write_cmds,
+                 &zufs_test_opts);
+    qos_add_test("zufs-open-zones", "ufs", ufstest_zufs_open_zones,
+                 &zufs_test_opts);
+    qos_add_test("zufs-unit-attention", "ufs", ufstest_zufs_unit_attention,
+                 &zufs_test_opts);
+    qos_add_test("zufs-report-zones", "ufs", ufstest_zufs_report_zones,
+                 &zufs_test_opts);
+    qos_add_test("zufs-conv-zones", "ufs", ufstest_zufs_conv_zones,
+                 &zufs_test_opts);
+    qos_add_test("zufs-hce-reset", "ufs", ufstest_zufs_hce_reset,
+                 &zufs_test_opts);
+    qos_add_test("zufs-report-dma-regs", "ufs", ufstest_zufs_report_dma_regs,
+                 &zufs_test_opts);
+    qos_add_test("zufs-mcq-cleanup", "ufs", ufstest_zufs_mcq_cleanup,
+                 &zufs_mcq_test_opts);
+    qos_add_test("zufs-mcq-abort", "ufs", ufstest_zufs_mcq_abort,
+                 &zufs_mcq_test_opts);
+    qos_add_test("zufs-mcq-cleanup-cq-full", "ufs",
+                 ufstest_zufs_mcq_cleanup_cq_full, &zufs_mcq_test_opts);
+    qos_add_test("zufs-more-cmds", "ufs", ufstest_zufs_more_cmds,
+                 &zufs_test_opts);
 }
 
 libqos_init(ufs_register_nodes);

-- 
2.43.0

