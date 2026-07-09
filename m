From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 10 Jul 2026 02:35:31 +0800
Subject: [PATCH v2] pvscsi: translate data endianness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-pvscsi-endianness-v2-1-c512e6c8849b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPLpT2oC/32NTQrDIBBGrxJmXYva/K96j5JFomMy0GhwirSE3
 L02B+jyPfjetwNjJGToix0iJmIKPoO+FGCW0c8oyGYGLXUta1mJLbFhEugtjd4jszDS3trOtro
 pEfJui+jofTYfQ+aF+BXi57xI6mf/1ZISSkxycmWjJ+mq7j6vIz2vJqwwHMfxBTiCJZWyAAAA
X-Change-ID: 20260605-pvscsi-endianness-c0d389d8274e
To: qemu-devel@nongnu.org
Cc: Paolo Bonzini <pbonzini@redhat.com>, Fam Zheng <fam@euphon.net>, 
 Dmitry Fleytman <dmitry.fleytman@gmail.com>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@oss.qualcomm.com>, 
 Peter Maydell <peter.maydell@linaro.org>, Michael Tokarev <mjt@tls.msk.ru>, 
 b4-sent@feeds.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6283;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=DL30zIks6In3NDYGK7v7j3XM1TzYPDzc1gG49FgIrI0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT+n1k6mjcpdPM0IlrnBEXRN0hCrQBshzNRlLr
 hQkpXRmH6GJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/p9QAKCRCwMePKe/7Z
 bhe7EACLlb33eiVmqoqiv5GydEbatzEGmZI+A7y96ed6o48TWJ7Hywzk5NO/j3A7VbXGHHifr34
 GT3278iK76R3P5NRgr8W18HdZXYUobb24WPImIr3R06ibphM+x/VF2nGLIFewuI7WvylbQmFqyd
 vBvyMGJ9raLqfpBPjkLw4TiSRL6874A9yLenksBaPHXlXtqVY3sp/zGEP7qj1Es2k55zy77GaZv
 Nuy+hNOmV344pgsdZlAePYbLsvGqmSH6KLBHGlDoE/4/O5kyjjsj9yGL5V5McHWAW7P9jVAsZp2
 u11N7/13AxNCX2r3teuwYSIwbfW5NEBbSp63k0u2hT3PopWK8xo04vK5A1/K2DaqoXSVNo4nBIh
 eTQ8XDP35rYj5bU2pnmK3w4YU0ctg8ZdQ2DCd/qBwhMYIdj+jdRYKRdvKdZeVn7Ywp66yYrdFTB
 cz6hsWFYtAHNmFcXByTpPtmic8alfnLPozR0XmkbTefjcrM9lPcX9RSZ1HhiIolMMVwbZgc3aL+
 Y5ilZq6DGNsBmVkA+MmCFoXzWQLht3w22oKYqoRW+xmAAgpGCqQixD9yX1/GDKF9tCI0x2Y8Oh1
 CvkIevoRbd+hpdAqOI0AwYCoKOyYOGcjDzxkdfB/WRVOffr2vJ/Dz5IJ6XVWpKNaDSuPjR9IMIH
 zzcPTixpn89IFQw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch improves the implementation of the pvscsi device by
translating the endianness of the data sent or received from the guest.
This ensures pvscsi can work on big-endian hosts with little-endian
guests.

This patch assumes, although not having found any specifications, that
the pvscsi device is little-endian, since pvscsi seems to be used only
on x86 platforms, which are little-endian.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v2:
- Assume pvscsi is little-endian instead of native-endian, and thus
  replace tswap*() with le*_to_cpu() and cpu_to_le*() to convert the
  endianness of pvscsi data structures to/from CPU endianness.
- Link to v1: https://lore.kernel.org/qemu-devel/20260605-pvscsi-endianness-v1-1-b0bf472b0f59@gmail.com
---
 hw/scsi/vmw_pvscsi.c | 57 +++++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 56 insertions(+), 1 deletion(-)

diff --git a/hw/scsi/vmw_pvscsi.c b/hw/scsi/vmw_pvscsi.c
index 11ae6b9b7474b9bc87621137eb7911361b5fd721..e6befe9be2c49d1dc04e6e6384f9d24f7a6a4273 100644
--- a/hw/scsi/vmw_pvscsi.c
+++ b/hw/scsi/vmw_pvscsi.c
@@ -392,9 +392,18 @@ static void
 pvscsi_cmp_ring_put(PVSCSIState *s, struct PVSCSIRingCmpDesc *cmp_desc)
 {
     hwaddr cmp_descr_pa;
+    struct PVSCSIRingCmpDesc cmp_desc_conv;
 
     cmp_descr_pa = pvscsi_ring_pop_cmp_descr(&s->rings);
     trace_pvscsi_cmp_ring_put(cmp_descr_pa);
+    cmp_desc_conv = (struct PVSCSIRingCmpDesc) {
+        .context = cpu_to_le64(cmp_desc->context),
+        .dataLen = cpu_to_le64(cmp_desc->dataLen),
+        .senseLen = cpu_to_le32(cmp_desc->senseLen),
+        .hostStatus = cpu_to_le16(cmp_desc->hostStatus),
+        .scsiStatus = cpu_to_le16(cmp_desc->scsiStatus),
+    };
+    cmp_desc = &cmp_desc_conv;
     cpu_physical_memory_write(cmp_descr_pa, cmp_desc, sizeof(*cmp_desc));
 }
 
@@ -402,9 +411,18 @@ static void
 pvscsi_msg_ring_put(PVSCSIState *s, struct PVSCSIRingMsgDesc *msg_desc)
 {
     hwaddr msg_descr_pa;
+    struct PVSCSIRingMsgDesc msg_desc_conv;
+    int i;
 
     msg_descr_pa = pvscsi_ring_pop_msg_descr(&s->rings);
     trace_pvscsi_msg_ring_put(msg_descr_pa);
+    msg_desc_conv = (struct PVSCSIRingMsgDesc) {
+        .type = cpu_to_le32(msg_desc->type),
+    };
+    for (i = 0; i < ARRAY_SIZE(msg_desc->args); i++) {
+        msg_desc_conv.args[i] = cpu_to_le32(msg_desc->args[i]);
+    }
+    msg_desc = &msg_desc_conv;
     cpu_physical_memory_write(msg_descr_pa, msg_desc, sizeof(*msg_desc));
 }
 
@@ -481,6 +499,9 @@ pvscsi_get_next_sg_elem(PVSCSISGState *sg)
     struct PVSCSISGElement elem;
 
     cpu_physical_memory_read(sg->elemAddr, &elem, sizeof(elem));
+    elem.addr = le64_to_cpu(elem.addr);
+    elem.length = le32_to_cpu(elem.length);
+    elem.flags = le32_to_cpu(elem.flags);
     if ((elem.flags & ~PVSCSI_KNOWN_FLAGS) != 0) {
         /*
             * There is PVSCSI_SGE_FLAG_CHAIN_ELEMENT flag described in
@@ -759,6 +780,12 @@ pvscsi_process_io(PVSCSIState *s)
 
         trace_pvscsi_process_io(next_descr_pa);
         cpu_physical_memory_read(next_descr_pa, &descr, sizeof(descr));
+        descr.context = le64_to_cpu(descr.context);
+        descr.dataAddr = le64_to_cpu(descr.dataAddr);
+        descr.dataLen = le64_to_cpu(descr.dataLen);
+        descr.senseAddr = le64_to_cpu(descr.senseAddr);
+        descr.senseLen = le32_to_cpu(descr.senseLen);
+        descr.flags = le32_to_cpu(descr.flags);
         pvscsi_process_request_descriptor(s, &descr);
     }
 
@@ -808,6 +835,17 @@ pvscsi_on_cmd_setup_rings(PVSCSIState *s)
 {
     PVSCSICmdDescSetupRings *rc =
         (PVSCSICmdDescSetupRings *) s->curr_cmd_data;
+    PVSCSICmdDescSetupRings translated;
+    int i;
+
+    translated.reqRingNumPages = le32_to_cpu(rc->reqRingNumPages);
+    translated.cmpRingNumPages = le32_to_cpu(rc->cmpRingNumPages);
+    translated.ringsStatePPN = le64_to_cpu(rc->ringsStatePPN);
+    for (i = 0; i < PVSCSI_SETUP_RINGS_MAX_NUM_PAGES; i++) {
+        translated.reqRingPPNs[i] = le64_to_cpu(rc->reqRingPPNs[i]);
+        translated.cmpRingPPNs[i] = le64_to_cpu(rc->cmpRingPPNs[i]);
+    }
+    rc = &translated;
 
     trace_pvscsi_on_cmd_arrived("PVSCSI_CMD_SETUP_RINGS");
 
@@ -831,6 +869,11 @@ pvscsi_on_cmd_abort(PVSCSIState *s)
     PVSCSICmdDescAbortCmd *cmd = (PVSCSICmdDescAbortCmd *) s->curr_cmd_data;
     PVSCSIRequest *r, *next;
 
+    PVSCSICmdDescAbortCmd translated = *cmd;
+    translated.context = le32_to_cpu(cmd->context);
+    translated.target = le32_to_cpu(cmd->target);
+    cmd = &translated;
+
     trace_pvscsi_on_cmd_abort(cmd->context, cmd->target);
 
     QTAILQ_FOREACH_SAFE(r, &s->pending_queue, next, next) {
@@ -862,6 +905,10 @@ pvscsi_on_cmd_reset_device(PVSCSIState *s)
         (struct PVSCSICmdDescResetDevice *) s->curr_cmd_data;
     SCSIDevice *sdev;
 
+    PVSCSICmdDescResetDevice translated = *cmd;
+    translated.target = le32_to_cpu(cmd->target);
+    cmd = &translated;
+
     sdev = pvscsi_device_find(s, 0, cmd->target, cmd->lun, &target_lun);
 
     trace_pvscsi_on_cmd_reset_dev(cmd->target, (int) target_lun, sdev);
@@ -892,6 +939,14 @@ pvscsi_on_cmd_setup_msg_ring(PVSCSIState *s)
 {
     PVSCSICmdDescSetupMsgRing *rc =
         (PVSCSICmdDescSetupMsgRing *) s->curr_cmd_data;
+    PVSCSICmdDescSetupMsgRing translated = *rc;
+    int i;
+
+    translated.numPages = le32_to_cpu(rc->numPages);
+    for (i = 0; i < PVSCSI_SETUP_MSG_RING_MAX_NUM_PAGES; i++) {
+        translated.ringPPNs[i] = le64_to_cpu(rc->ringPPNs[i]);
+    }
+    rc = &translated;
 
     trace_pvscsi_on_cmd_arrived("PVSCSI_CMD_SETUP_MSG_RING");
 
@@ -994,7 +1049,7 @@ pvscsi_on_command_data(PVSCSIState *s, uint32_t value)
     size_t bytes_arrived = s->curr_cmd_data_cntr * sizeof(uint32_t);
 
     assert(bytes_arrived < sizeof(s->curr_cmd_data));
-    s->curr_cmd_data[s->curr_cmd_data_cntr++] = value;
+    s->curr_cmd_data[s->curr_cmd_data_cntr++] = cpu_to_le32(value);
 
     pvscsi_do_command_processing(s);
 }

---
base-commit: 29c042c6e9d4a09d4a0ac3fa54aeb7ee08ce0bdc
change-id: 20260605-pvscsi-endianness-c0d389d8274e

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

