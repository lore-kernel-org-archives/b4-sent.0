From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 22 Jun 2026 13:38:12 -0500
Subject: [PATCH v2] ata: libata-core: Reject an invalid concurrent
 positioning ranges count
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-b4-disp-5734c6f2-v2-1-53083c2df3c6@proton.me>
X-B4-Tracking: v=1; b=H4sIABOBOWoC/x3MMQqAMAxA0atIZgM1alu8ijhoTTSLSgsiSO9uc
 XzD/y8kjsoJhuqFyLcmPY8CqisI+3xsjLoWAxmyxhLh0uGq6cLetV2wQujFh9Y48Ys0ULIrsuj
 zL8cp5w8SWH5TYgAAAA==
To: Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-ide@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782153491; l=3597;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=s7iWl1A1AVZplle7BVcwv17DnZEN0SJ+S8DOR5LSvyE=;
 b=Z1+ABP+JLnIwd4pXZznefy3o/ZLLvQYGxWqSz0a3j1XWTTHIYdCGOGkYz63EgbznvSov33Mgv
 DdSo5rd3YTYDVtnmb1M9Hpc50NJP1rn9CTwNHr8Qez3HtGTZ7VkfosU
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
and the 62-descriptor capacity of the VPD B9h buffer; warn and ignore the
log when it does not fit. Capping the stored count keeps the emitter in
bounds with no separate change there.

Suggested-by: Damien Le Moal <dlemoal@kernel.org>
Fixes: fe22e1c2f705 ("libata: support concurrent positioning ranges log")
Fixes: c745dfc541e7 ("libata: fix reading concurrent positioning ranges log")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v2: Per Damien Le Moal's review, reject an inconsistent count instead of
    clamping it, and fold the emitter bound into this single probe-time
    check: a count above 62 (the VPD B9h 2048-byte buffer capacity) or one
    that does not fit the device's own log is rejected with a warning. That
    makes the separate emitter patch unnecessary, so v1 2/2 is dropped.
    v1 1/2: https://lore.kernel.org/all/20260619-b4-disp-6200c44e-v1-1-4624a4707d9e@proton.me/
    v1 2/2: https://lore.kernel.org/all/20260619-b4-disp-6200c44e-v1-2-4624a4707d9e@proton.me/

A/B with a userspace AddressSanitizer mirror of both sinks (-m64 and -m32;
the unbounded value is device log content, not bus state, so no hardware is
needed):

  count  buf_len  with this patch
  2      128      accepted (conforming drive)
  62     2048     accepted (62 actuators, the documented maximum)
  63     8704     rejected (exceeds the 62-descriptor VPD B9h buffer)
  255    8704     rejected (self-consistent log, but the emit would overflow)
  62     512      rejected (count does not fit the device's own log)
  255    512      rejected

Without the patch the 512-byte rows fault on the log read and the >62 rows
fault on the VPD B9h emit; with it every count the emitter can still receive
fits the 2048-byte buffer. Reproducer available on request.
---
 drivers/ata/libata-core.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/ata/libata-core.c b/drivers/ata/libata-core.c
index 3d0027ec33c2..017a16be158b 100644
--- a/drivers/ata/libata-core.c
+++ b/drivers/ata/libata-core.c
@@ -2832,6 +2832,18 @@ static void ata_dev_config_cpr(struct ata_device *dev)
 	if (!nr_cpr)
 		goto out;
 
+	/*
+	 * The count is reported independently of the log size and is also
+	 * emitted into the fixed 2048-byte VPD B9h buffer, which holds at most
+	 * (2048 - 64) / 32 = 62 descriptors. Reject a count that exceeds that
+	 * or does not fit the log the device returned.
+	 */
+	if (nr_cpr > 62 || buf_len < 64 + (size_t)nr_cpr * 32) {
+		ata_dev_warn(dev,
+			     "Invalid number of concurrent positioning ranges\n");
+		goto out;
+	}
+
 	cpr_log = kzalloc_flex(*cpr_log, cpr, nr_cpr);
 	if (!cpr_log)
 		goto out;

---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260622-b4-disp-5734c6f2-8f8c307f8bf1

Best regards,
-- 
bryamzxz <hexlabsecurity@proton.me>

