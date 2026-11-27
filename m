From: Ricardo Pardini <ricardo@pardini.net>
Date: Fri, 27 Nov 2026 14:13:00 +0100
Subject: [PATCH v2 3/4] ata: ahci: return the last LBA from emulated READ
 CAPACITY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-rk3588-sata-fixes-v2027-01-v2-3-dbdf7770972a@pardini.net>
References: <20261127-rk3588-sata-fixes-v2027-01-v2-0-dbdf7770972a@pardini.net>
In-Reply-To: <20261127-rk3588-sata-fixes-v2027-01-v2-0-dbdf7770972a@pardini.net>
To: u-boot@lists.u-boot-project.org, Simon Glass <sjg@chromium.org>, 
 Kever Yang <kever.yang@rock-chips.com>, Eugen Hristev <ehristev@kernel.org>, 
 Jon Lin <jon.lin@rock-chips.com>
Cc: Tom Rini <trini@konsulko.com>, Peng Fan <peng.fan@nxp.com>, 
 Ricardo Pardini <ricardo@pardini.net>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Heiko Stuebner <heiko@sntech.de>, Julius Lehmann <lehmanju@devpi.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1809; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=9TIiApzFn3xQtzGU/fV7KRaSTT+cb2gTL4l52MT6QlY=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBrCYIa2sv7PQWFUDvqq7FQRJ1X8BXafGqvUCpsb
 fhOUI3YlbWJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCawmCGgAKCRA7Xj/jnsft
 6eWJB/9Bl6kDQkGdnELraR1J0aAJI83xCH+5LO8CKlqrj/f5SoqqqKTtXgd8ZCISfNMiQd/l77T
 Ml+FHNWd+SAa1rn4UKQID3djbnRZ6oa0SmALHcLF8UmWIeXss3m+IlhwHKYvUwFliVhbpj5Bqcs
 MiSATZnca6uB6eWzwcztJUxxYi9XV2R/IJWU01bhev6xiM2wlE7fw+oFlnXcoYlL6gTjuO5lNs+
 kCwA6fvlNsWilR3mv64DQqv9lwdqmvco2MdfawAvX+QMVanNdgtpWbkFBesMsRSgJ6W4KX10HFO
 WmHnes/BNv7LZmC1ggyTZXwM1QvZzN1ivTb25/4uBRlbHjMp
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SCSI READ CAPACITY returns the address of the last block, and since
commit 5f7c06bdc3c6 ("scsi: fix disk capacity too small by one sector")
scsi_read_capacity() adds one to get the block count. The AHCI emulation
returns the sector count instead, so AHCI disks are now reported one
sector too large.

Reading that non-existent sector ends in a 10 s AHCI timeout. With
"ums 0 scsi 0" this happens as soon as the host looks for the backup
GPT, and UMS exits.

Return n_sectors - 1 from both handlers, keeping the READ CAPACITY (10)
clamp.

Fixes: 5f7c06bdc3c6 ("scsi: fix disk capacity too small by one sector")
Cc: Julius Lehmann <lehmanju@devpi.de>
Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
Reviewed-by: Quentin Schulz <quentin.schulz@cherry.de>
---
 drivers/ata/ahci.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index 38e953ee79c..c806ee55d70 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -759,8 +759,9 @@ static int ata_scsiop_read_capacity10(struct ahci_uc_priv *uc_priv,
 		return -EPERM;
 	}
 
-	cap64 = ata_id_n_sectors(uc_priv->ataid[pccb->target]);
-	if (cap64 > 0x100000000ULL)
+	/* READ CAPACITY returns the address of the last block */
+	cap64 = ata_id_n_sectors(uc_priv->ataid[pccb->target]) - 1;
+	if (cap64 > 0xffffffffULL)
 		cap64 = 0xffffffff;
 
 	cap = cpu_to_be32(cap64);
@@ -788,7 +789,8 @@ static int ata_scsiop_read_capacity16(struct ahci_uc_priv *uc_priv,
 		return -EPERM;
 	}
 
-	cap = ata_id_n_sectors(uc_priv->ataid[pccb->target]);
+	/* READ CAPACITY returns the address of the last block */
+	cap = ata_id_n_sectors(uc_priv->ataid[pccb->target]) - 1;
 	cap = cpu_to_be64(cap);
 	memcpy(pccb->pdata, &cap, sizeof(cap));
 

-- 
2.47.3

