From: Ricardo Pardini <ricardo@pardini.net>
Date: Mon, 09 Nov 2026 03:57:59 +0100
Subject: [PATCH 2/3] ata: ahci: return the last LBA from emulated READ
 CAPACITY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-rk3588-sata-fixes-v2027-01-v1-2-e54ca8e68f18@pardini.net>
References: <20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net>
In-Reply-To: <20261109-rk3588-sata-fixes-v2027-01-v1-0-e54ca8e68f18@pardini.net>
To: u-boot@lists.u-boot-project.org, Simon Glass <sjg@chromium.org>, 
 Kever Yang <kever.yang@rock-chips.com>, Eugen Hristev <ehristev@kernel.org>, 
 Jon Lin <jon.lin@rock-chips.com>
Cc: Tom Rini <trini@konsulko.com>, Peng Fan <peng.fan@nxp.com>, 
 Ricardo Pardini <ricardo@pardini.net>, Quentin Schulz <u-boot@0leil.net>, 
 Jonas Karlman <jonas@kwiboo.se>, Heiko Stuebner <heiko@sntech.de>, 
 Julius Lehmann <lehmanju@devpi.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1753; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=TpqtpTeordKsp8pC6pBN2hKI/3qXUwYzN0QB8smmshU=;
 b=owGbwMvMwMVoHWf/eN7xty8ZT6slMWR9NNu+MUzaKeyqY4/lKqnCsARzPbsXM5y/P0+f2Pgk+
 omtrPGuTkZjFgZGLgZZMUWWNRLKPN/Wvzp1x6NjMswgViaQKQxcnAIwETkV9v8RZfaXJnP6K6ed
 2rFq+xXW+4uNGK9z3jPxWf8pZaeK4CW3L27Jd6O91pY9qTgSr+xTE/gp8YzH6ov/F4jMvzq1OMt
 VdvJPjjoR/a+yche+a71U+1RifHXj3eLdYqEqk/RW+9Y7rr91IdmzuLUn6czRTYsyLDcHp0UJ60
 2vn8JxtszGc6Nwxf+X34yDeyYKGTPKvZzq8Mtycb6JWx5H/UX+LK/PevoyL1SMWm2mHgwv4Iksb
 baJy7gRLmSg8eV2WejtVKGm4E0O9ZHvWB+b5O0+ws0tN2HF7KICma8pXapN4ZnPFDWr23iZ5kia
 RG+If21lGiz6bo6Dc8Bj6aOTU9+6vf2/2bWIMfMOR8l5AA==
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

