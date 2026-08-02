From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:27 +0200
Subject: [PATCH v3 11/15] ata: ahci: add helper for ATA commands without
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-11-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=1078;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=tsY7GPVDrmTr0Jjsz7fL+Yu5UV/pmkPT8sqzkIvC8tY=;
 b=OLZkfaLPIsR9TJT4QOc6Azua9gTNlo2SfHClndwVCTD5DX3FG01yBeVljCUTLCH2PDKdgcA9i
 L7HOFPWqle7BtwpkCnTgcqIg1siJNLuQ+ZPj/Ibn0dXmW96Ke8p4pH1
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce ahci_ata_nodata(), a small wrapper that prepares a FIS and
submits an AHCI command without PRDT entries or DMA setup. This avoids
duplicating zero-length handling logic across callers and simplifies
ATA command submission paths.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index a080de236e..09d37720c2 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -238,6 +238,21 @@ static int ahci_io(struct ahci_port *ahci_port, u8 *fis, int fis_len, void *rbuf
 	return ret;
 }
 
+static int ahci_ata_nodata(struct ahci_port *ahci, u8 command, u8 feature)
+{
+	u8 fis[20] = {
+		0x27,        /* Host to device FIS */
+		1 << 7,      /* Command FIS */
+		command,     /* Command */
+		feature,     /* Features */
+	};
+
+	if (!ahci_link_ok(ahci, 0))
+		return -ENODEV;
+
+	return ahci_io(ahci, fis, sizeof(fis), NULL, NULL, 0);
+}
+
 /*
  * SCSI INQUIRY command operation.
  */

-- 
2.47.3

