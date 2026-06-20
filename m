From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 19 Jun 2026 21:36:30 -0500
Subject: [PATCH 2/2] ata: libata-scsi: Bound the VPD B9h ranges to the
 response buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-b4-disp-6200c44e-v1-2-4624a4707d9e@proton.me>
References: <20260619-b4-disp-6200c44e-v1-0-4624a4707d9e@proton.me>
In-Reply-To: <20260619-b4-disp-6200c44e-v1-0-4624a4707d9e@proton.me>
To: Damien Le Moal <dlemoal@kernel.org>, Niklas Cassel <cassel@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781922988; l=2123;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=etuEVYLjhJ1FT+81wFk8q9Lg1k6MxM4NwywWjYbfzbc=;
 b=5qN0S5L3QVPbKFwwEJSUL8skJpsnwJX8mO+Eg7n3G9ubCEDKtTMKNd8lEwhwe33gjJhKcfonW
 DLfIDhYdb8yBTgZs6d/DHw4KFUy8A2YvXVrmjbgLYuTs/GQd7mzBHxO
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ata_scsiop_inq_b9() writes one 32-byte range descriptor per
cpr_log->nr_cpr into the fixed 2048-byte ata_scsi_rbuf with no bound.
The count originates from the device (concurrent positioning ranges log
0x47, up to 255), so an INQUIRY VPD page B9h to a drive whose log
advertises more than 62 ranges overflows the static buffer by up to 6168
bytes: a global out-of-bounds write into adjacent kernel data.

Emit only as many descriptors as the response buffer can hold and size
the page length to match. The companion core fix bounds the stored count
against the device log, but a large self-consistent log still yields
nr_cpr up to 255, so the emitter needs its own bound.

Fixes: fe22e1c2f705 ("libata: support concurrent positioning ranges log")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 drivers/ata/libata-scsi.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/ata/libata-scsi.c b/drivers/ata/libata-scsi.c
index d43207c6e467..d43306c5d375 100644
--- a/drivers/ata/libata-scsi.c
+++ b/drivers/ata/libata-scsi.c
@@ -2355,18 +2355,24 @@ static unsigned int ata_scsiop_inq_b9(struct ata_device *dev,
 {
 	struct ata_cpr_log *cpr_log = dev->cpr_log;
 	u8 *desc = &rbuf[64];
-	int i;
+	int i, nr_cpr;
 
 	if (!cpr_log) {
 		ata_scsi_set_invalid_field(dev, cmd, 2, 0xff);
 		return 0;
 	}
 
+	/*
+	 * The page is built in the fixed-size ata_scsi_rbuf, so the number of
+	 * range descriptors returned is bounded by that buffer's size.
+	 */
+	nr_cpr = min_t(int, cpr_log->nr_cpr, (ATA_SCSI_RBUF_SIZE - 64) / 32);
+
 	/* SCSI Concurrent Positioning Ranges VPD page: SBC-5 rev 1 or later */
 	rbuf[1] = 0xb9;
-	put_unaligned_be16(64 + (int)cpr_log->nr_cpr * 32 - 4, &rbuf[2]);
+	put_unaligned_be16(64 + nr_cpr * 32 - 4, &rbuf[2]);
 
-	for (i = 0; i < cpr_log->nr_cpr; i++, desc += 32) {
+	for (i = 0; i < nr_cpr; i++, desc += 32) {
 		desc[0] = cpr_log->cpr[i].num;
 		desc[1] = cpr_log->cpr[i].num_storage_elements;
 		put_unaligned_be64(cpr_log->cpr[i].start_lba, &desc[8]);

-- 
2.43.0

