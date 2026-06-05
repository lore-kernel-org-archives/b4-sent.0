From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 05 Jun 2026 21:27:56 +0800
Subject: [PATCH] pvscsi: translate data endianness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-pvscsi-endianness-v1-1-b0bf472b0f59@gmail.com>
X-B4-Tracking: v=1; b=H4sIANvOImoC/x3MPQqAMAxA4atIZgO1av25ijiUNmqWKA2IULy7x
 fEb3suglJgU5ipDopuVTylo6grC4WUn5FgM1lhnnOnxujUoI0lkL0KqGExsxymOdugISncl2vj
 5n8v6vh+FHf2KYwAAAA==
X-Change-ID: 20260605-pvscsi-endianness-c0d389d8274e
To: qemu-devel@nongnu.org
Cc: Paolo Bonzini <pbonzini@redhat.com>, Fam Zheng <fam@euphon.net>, 
 Dmitry Fleytman <dmitry.fleytman@gmail.com>, b4-sent@feeds.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5870;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=IDD6ngFrpnNwjIvo7mlAG2CQIH9yKzKqEbqAPfV7ac0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqIs7iFHWdvYvQ+eHP9PcejZHcy/LnvqNiXlcWM
 e7YklLHYPWJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCaiLO4gAKCRCwMePKe/7Z
 bvS4D/wKIdrGYEL3DI3HZCBXXOk9aU2wsxAtYO5cbqjZ8vLFHR0ATWwCdoaCO70tUyUgBkCO/VW
 vRqEPJBuyFhwhaYLkng7MvnzuvJHMmI9/e2OHtDNMc18nKVv5Mwd9lJ+Se3e3NOCkTSWATS1Jq7
 IZd3jy7YiYzLA7U5N1smRHPGj2ilQG5Mrv6Bej3THc9rHqPwhOZG/Od6KC1PagRZXCRVNcMGqOS
 jkArL8MTqhkD4APNBZGBBaHn7/qjsfq42qrQzAwPMuhqzrtP24OUtkM84RJiskmm1ocQOVs5V3+
 EUp7ogXcFip1xzfLD6DDy0kW4cZAe4/hKvQt5nK6dx+y2ksbez7RXc3w8Q7ecYBVvgZ1AyRNtxd
 JldOH2p+XHWvQiWck8jyhEyNQ3RwREi+qRviNMidpXR9TtJCzdqPtJeU79FkzoLnPzaiyFV4/ja
 eVFc3jlswCd6WrMNH3k6Ob/nKjZbtECWJe8CTd8IGuNyyxwIBoMkk62blKM2HAf6F67wZBgDpn2
 GFRQvWUoyrTHX5Yh7iaFJzRksnTmumoZT/VcdbdFgDZV362qwr0VT30+d1xwqN5a2V/Fmct9N+Z
 qFSAs0oPM7x2xnEUjwVaiVvOSAsQt3otfnFDN42+2AKPn5PAkVV2LU9XVNi/s4w2T52h9xLbTT9
 0W8OUxDTk5ei9hg==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch improves the implementation of the pvscsi device by
translating the endianness of the data sent or received from the guest.
This ensures pvscsi can work on big-endian hosts with little-endian
guests.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 hw/scsi/vmw_pvscsi.c | 58 +++++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 57 insertions(+), 1 deletion(-)

diff --git a/hw/scsi/vmw_pvscsi.c b/hw/scsi/vmw_pvscsi.c
index 11ae6b9b7474b9bc87621137eb7911361b5fd721..883dfe9b6b5dc687737de356da02fe5f68aea7ad 100644
--- a/hw/scsi/vmw_pvscsi.c
+++ b/hw/scsi/vmw_pvscsi.c
@@ -35,6 +35,7 @@
 #include "hw/pci/msi.h"
 #include "hw/core/qdev-properties.h"
 #include "exec/cpu-common.h"
+#include "exec/tswap.h"
 #include "vmw_pvscsi.h"
 #include "trace.h"
 #include "qom/object.h"
@@ -392,9 +393,18 @@ static void
 pvscsi_cmp_ring_put(PVSCSIState *s, struct PVSCSIRingCmpDesc *cmp_desc)
 {
     hwaddr cmp_descr_pa;
+    struct PVSCSIRingCmpDesc cmp_desc_conv;
 
     cmp_descr_pa = pvscsi_ring_pop_cmp_descr(&s->rings);
     trace_pvscsi_cmp_ring_put(cmp_descr_pa);
+    cmp_desc_conv = (struct PVSCSIRingCmpDesc) {
+        .context = tswap64(cmp_desc->context),
+        .dataLen = tswap64(cmp_desc->dataLen),
+        .senseLen = tswap32(cmp_desc->senseLen),
+        .hostStatus = tswap16(cmp_desc->hostStatus),
+        .scsiStatus = tswap16(cmp_desc->scsiStatus),
+    };
+    cmp_desc = &cmp_desc_conv;
     cpu_physical_memory_write(cmp_descr_pa, cmp_desc, sizeof(*cmp_desc));
 }
 
@@ -402,9 +412,18 @@ static void
 pvscsi_msg_ring_put(PVSCSIState *s, struct PVSCSIRingMsgDesc *msg_desc)
 {
     hwaddr msg_descr_pa;
+    struct PVSCSIRingMsgDesc msg_desc_conv;
+    int i;
 
     msg_descr_pa = pvscsi_ring_pop_msg_descr(&s->rings);
     trace_pvscsi_msg_ring_put(msg_descr_pa);
+    msg_desc_conv = (struct PVSCSIRingMsgDesc) {
+        .type = tswap32(msg_desc->type),
+    };
+    for (i = 0; i < ARRAY_SIZE(msg_desc->args); i++) {
+        msg_desc_conv.args[i] = tswap32(msg_desc->args[i]);
+    }
+    msg_desc = &msg_desc_conv;
     cpu_physical_memory_write(msg_descr_pa, msg_desc, sizeof(*msg_desc));
 }
 
@@ -481,6 +500,9 @@ pvscsi_get_next_sg_elem(PVSCSISGState *sg)
     struct PVSCSISGElement elem;
 
     cpu_physical_memory_read(sg->elemAddr, &elem, sizeof(elem));
+    elem.addr = tswap64(elem.addr);
+    elem.length = tswap32(elem.length);
+    elem.flags = tswap32(elem.flags);
     if ((elem.flags & ~PVSCSI_KNOWN_FLAGS) != 0) {
         /*
             * There is PVSCSI_SGE_FLAG_CHAIN_ELEMENT flag described in
@@ -759,6 +781,12 @@ pvscsi_process_io(PVSCSIState *s)
 
         trace_pvscsi_process_io(next_descr_pa);
         cpu_physical_memory_read(next_descr_pa, &descr, sizeof(descr));
+        descr.context = tswap64(descr.context);
+        descr.dataAddr = tswap64(descr.dataAddr);
+        descr.dataLen = tswap64(descr.dataLen);
+        descr.senseAddr = tswap64(descr.senseAddr);
+        descr.senseLen = tswap32(descr.senseLen);
+        descr.flags = tswap32(descr.flags);
         pvscsi_process_request_descriptor(s, &descr);
     }
 
@@ -808,6 +836,17 @@ pvscsi_on_cmd_setup_rings(PVSCSIState *s)
 {
     PVSCSICmdDescSetupRings *rc =
         (PVSCSICmdDescSetupRings *) s->curr_cmd_data;
+    PVSCSICmdDescSetupRings translated;
+    int i;
+
+    translated.reqRingNumPages = tswap32(rc->reqRingNumPages);
+    translated.cmpRingNumPages = tswap32(rc->cmpRingNumPages);
+    translated.ringsStatePPN = tswap64(rc->ringsStatePPN);
+    for (i = 0; i < PVSCSI_SETUP_RINGS_MAX_NUM_PAGES; i++) {
+        translated.reqRingPPNs[i] = tswap64(rc->reqRingPPNs[i]);
+        translated.cmpRingPPNs[i] = tswap64(rc->cmpRingPPNs[i]);
+    }
+    rc = &translated;
 
     trace_pvscsi_on_cmd_arrived("PVSCSI_CMD_SETUP_RINGS");
 
@@ -831,6 +870,11 @@ pvscsi_on_cmd_abort(PVSCSIState *s)
     PVSCSICmdDescAbortCmd *cmd = (PVSCSICmdDescAbortCmd *) s->curr_cmd_data;
     PVSCSIRequest *r, *next;
 
+    PVSCSICmdDescAbortCmd translated = *cmd;
+    translated.context = tswap32(cmd->context);
+    translated.target = tswap32(cmd->target);
+    cmd = &translated;
+
     trace_pvscsi_on_cmd_abort(cmd->context, cmd->target);
 
     QTAILQ_FOREACH_SAFE(r, &s->pending_queue, next, next) {
@@ -862,6 +906,10 @@ pvscsi_on_cmd_reset_device(PVSCSIState *s)
         (struct PVSCSICmdDescResetDevice *) s->curr_cmd_data;
     SCSIDevice *sdev;
 
+    PVSCSICmdDescResetDevice translated = *cmd;
+    translated.target = tswap32(cmd->target);
+    cmd = &translated;
+
     sdev = pvscsi_device_find(s, 0, cmd->target, cmd->lun, &target_lun);
 
     trace_pvscsi_on_cmd_reset_dev(cmd->target, (int) target_lun, sdev);
@@ -892,6 +940,14 @@ pvscsi_on_cmd_setup_msg_ring(PVSCSIState *s)
 {
     PVSCSICmdDescSetupMsgRing *rc =
         (PVSCSICmdDescSetupMsgRing *) s->curr_cmd_data;
+    PVSCSICmdDescSetupMsgRing translated = *rc;
+    int i;
+
+    translated.numPages = tswap32(rc->numPages);
+    for (i = 0; i < PVSCSI_SETUP_MSG_RING_MAX_NUM_PAGES; i++) {
+        translated.ringPPNs[i] = tswap64(rc->ringPPNs[i]);
+    }
+    rc = &translated;
 
     trace_pvscsi_on_cmd_arrived("PVSCSI_CMD_SETUP_MSG_RING");
 
@@ -994,7 +1050,7 @@ pvscsi_on_command_data(PVSCSIState *s, uint32_t value)
     size_t bytes_arrived = s->curr_cmd_data_cntr * sizeof(uint32_t);
 
     assert(bytes_arrived < sizeof(s->curr_cmd_data));
-    s->curr_cmd_data[s->curr_cmd_data_cntr++] = value;
+    s->curr_cmd_data[s->curr_cmd_data_cntr++] = tswap32(value);
 
     pvscsi_do_command_processing(s);
 }

---
base-commit: 29c042c6e9d4a09d4a0ac3fa54aeb7ee08ce0bdc
change-id: 20260605-pvscsi-endianness-c0d389d8274e

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

