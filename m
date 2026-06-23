From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 22 Jun 2026 22:23:45 -0500
Subject: [PATCH v3] ata: libata-core: Reject an invalid concurrent
 positioning ranges count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-b4-disp-1b9ba697-v3-1-14ac65dd4413@proton.me>
X-B4-Tracking: v=1; b=H4sIAED8OWoC/x3MMQqAMAxA0atIZgM1akSvIg6NjZpFpQURxLtbH
 N/w/wNJo2mCoXgg6mXJjj2jLguYN7+vihaygRyxYyKUBoOlEyvpxXPfIXNbu1A1XoQgZ2fUxe5
 /OU7v+wE9a3+AYgAAAA==
To: Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782185024; l=5345;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=Ec/mFCp+NfHtkSGHo6KpjWMP+g6mOzbrM1+SN3wap1o=;
 b=yTe/Djr7/nk5qpt+L2pLP+4nPOCRiEbr/QY45eJ8c5i1bohtBMrZT9qlfq9CvJM3Uu7kLcaUA
 Hhl17d867smBw83lA/NG7WhDdIGMEYy543/35Hl36xIygjJIb7Z8pAN
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ata_dev_config_cpr() takes the number of range descriptors from buf[0]
of the concurrent positioning ranges log (up to 255), which the device
reports independently of the log size in the GPL directory. The count is
then walked at a fixed 32-byte stride in two places with no bound: the
log read here, and the INQUIRY VPD page B9h emitter, which writes one
descriptor per range into the fixed 2048-byte ata_scsi_rbuf. A device
reporting a count larger than its own log overflows the read buffer (up
to 7704 bytes past a 512-byte slab), and a count above 62 overflows the
response buffer on the emit side.

Bound the count once, on probe, against both the log the device returned
and the number of descriptors the VPD B9h response buffer can hold
(ATA_DEV_MAX_CPR, derived from the rbuf size). Reject an out-of-range
count with a warning; this keeps the emitter in bounds with no separate
change there.

Suggested-by: Damien Le Moal <dlemoal@kernel.org>
Fixes: fe22e1c2f705 ("libata: support concurrent positioning ranges log")
Fixes: c745dfc541e7 ("libata: fix reading concurrent positioning ranges log")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3: Per Damien Le Moal's review of v2, derive the limit from the response
    buffer size instead of hard-coding 62: define ATA_DEV_MAX_CPR in
    drivers/ata/libata.h (moving ATA_SCSI_RBUF_SIZE there so the producer
    cap and the consumer buffer reference one value), split the two bounds
    into separate checks with distinct warnings, and note in the comment
    that the ACS specs allow up to 255 ranges but we limit to what fits the
    VPD B9h buffer. ATA_DEV_MAX_CPR evaluates to 62, so there is no
    behavioural change.
    v2:     https://lore.kernel.org/all/20260622-b4-disp-5734c6f2-v2-1-53083c2df3c6@proton.me/
    v1 1/2: https://lore.kernel.org/all/20260619-b4-disp-6200c44e-v1-1-4624a4707d9e@proton.me/
    v1 2/2: https://lore.kernel.org/all/20260619-b4-disp-6200c44e-v1-2-4624a4707d9e@proton.me/

A/B with a userspace AddressSanitizer mirror of both sinks (-m64 and -m32;
the unbounded value is device log content, not bus state, so no hardware is
needed):

  count  buf_len  with this patch
  2      128      accepted (conforming drive)
  62     2048     accepted (62 actuators, the documented maximum)
  63     8704     rejected (exceeds the VPD B9h buffer capacity)
  255    8704     rejected (self-consistent log, but the emit would overflow)
  62     512      rejected (count does not fit the device's own log)
  255    512      rejected

Without the patch the 512-byte rows fault on the log read and the >62 rows
fault on the VPD B9h emit; with it every count the emitter can still receive
fits the 2048-byte buffer. Reproducer available on request.
---
 drivers/ata/libata-core.c | 18 ++++++++++++++++++
 drivers/ata/libata-scsi.c |  2 --
 drivers/ata/libata.h      |  9 +++++++++
 3 files changed, 27 insertions(+), 2 deletions(-)

diff --git a/drivers/ata/libata-core.c b/drivers/ata/libata-core.c
index 3d0027ec33c2..437f790ccc88 100644
--- a/drivers/ata/libata-core.c
+++ b/drivers/ata/libata-core.c
@@ -2832,6 +2832,24 @@ static void ata_dev_config_cpr(struct ata_device *dev)
 	if (!nr_cpr)
 		goto out;
 
+	/*
+	 * The device reports the number of CPR descriptors independently of the
+	 * log size, and that count is also used to emit VPD page B9h into the
+	 * fixed-size rbuf. Reject a count larger than what that buffer can hold
+	 * (ATA_DEV_MAX_CPR) or larger than the log the device actually returned.
+	 */
+	if (nr_cpr > ATA_DEV_MAX_CPR) {
+		ata_dev_warn(dev,
+			     "Too many concurrent positioning ranges\n");
+		goto out;
+	}
+
+	if (buf_len < 64 + (size_t)nr_cpr * 32) {
+		ata_dev_warn(dev,
+			     "Invalid number of concurrent positioning ranges\n");
+		goto out;
+	}
+
 	cpr_log = kzalloc_flex(*cpr_log, cpr, nr_cpr);
 	if (!cpr_log)
 		goto out;
diff --git a/drivers/ata/libata-scsi.c b/drivers/ata/libata-scsi.c
index d43207c6e467..0b5b3afd8f57 100644
--- a/drivers/ata/libata-scsi.c
+++ b/drivers/ata/libata-scsi.c
@@ -37,8 +37,6 @@
 #include "libata.h"
 #include "libata-transport.h"
 
-#define ATA_SCSI_RBUF_SIZE	2048
-
 static DEFINE_SPINLOCK(ata_scsi_rbuf_lock);
 static u8 ata_scsi_rbuf[ATA_SCSI_RBUF_SIZE];
 
diff --git a/drivers/ata/libata.h b/drivers/ata/libata.h
index b5423b6e97de..329e9c5776f0 100644
--- a/drivers/ata/libata.h
+++ b/drivers/ata/libata.h
@@ -148,6 +148,15 @@ static inline bool ata_acpi_dev_manage_restart(struct ata_device *dev) { return
 #endif
 
 /* libata-scsi.c */
+#define ATA_SCSI_RBUF_SIZE	2048
+
+/*
+ * Maximum number of concurrent positioning ranges (CPR) supported. The ACS
+ * specifications allow up to 255, but we limit this to the number of CPR
+ * descriptors that fit in the rbuf buffer used to emit VPD page B9h.
+ */
+#define ATA_DEV_MAX_CPR		min(255, ((ATA_SCSI_RBUF_SIZE - 64) / 32))
+
 extern struct ata_device *ata_scsi_find_dev(struct ata_port *ap,
 					    const struct scsi_device *scsidev);
 extern int ata_scsi_add_hosts(struct ata_host *host,

---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260622-b4-disp-1b9ba697-66530d14abb2

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

