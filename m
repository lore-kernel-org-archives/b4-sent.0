From: Peter-Simon Dieterich <peter-simon.dieterich@vaillant-group.com>
Date: Thu, 17 Sep 2026 15:00:43 +0200
Subject: [PATCH 2/2] mtd: rawnand: Reflect that ESMT and GigaDevice share
 ID 0xc8
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-esmt-gd9fu2g8f3a-v1-2-577c0ab2d31a@vaillant-group.com>
References: <20260917-esmt-gd9fu2g8f3a-v1-0-577c0ab2d31a@vaillant-group.com>
In-Reply-To: <20260917-esmt-gd9fu2g8f3a-v1-0-577c0ab2d31a@vaillant-group.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Peter-Simon Dieterich <peter-simon.dieterich@vaillant-group.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789650050; l=1759;
 i=peter-simon.dieterich@vaillant-group.com; s=20260820;
 h=from:subject:message-id; bh=GVgrbaeNYYC74jEu4meBBZ7WRozFmcBvWG5whH/D0VM=;
 b=l0SsMisYo5Dfq77I3F5DLjARmFARoNm+su+9JXxGB+DtQTaQrbkkGFRcVSCRzJQ4zmwFZdYYk
 oLMu8xtFbkRASk2T/LZE2YjQ83lC8FgGTFHxMwqqWNHGT7upYXwwOT9
X-Developer-Key: i=peter-simon.dieterich@vaillant-group.com; a=ed25519;
 pk=YI8VL1pBCnAIu0GVWI3a6qn/SG0pMQhm9n/RZTI5KZg=
X-Endpoint-Received: by B4 Relay for peter-simon.dieterich@vaillant-group.com/20260820 with auth_id=965
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

JEDEC manufacturer ID 0xc8 is used by both ESMT and GigaDevice, so
nand_esmt.c handles chips from both vendors. Chips from either
vendor are currently reported as "ESMT", which is misleading when
debugging a GigaDevice part.

Rename the manufacturer entry to "ESMT/GigaDevice" and document the
collision next to the NAND_MFR_ESMT definition. The only behavioural
change is the manufacturer name printed at detection time.

Signed-off-by: Peter-Simon Dieterich <peter-simon.dieterich@vaillant-group.com>
---
 drivers/mtd/nand/raw/internals.h | 1 +
 drivers/mtd/nand/raw/nand_ids.c  | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/mtd/nand/raw/internals.h b/drivers/mtd/nand/raw/internals.h
index b7162ced9efa..b8b29341b88c 100644
--- a/drivers/mtd/nand/raw/internals.h
+++ b/drivers/mtd/nand/raw/internals.h
@@ -19,6 +19,7 @@
 #define NAND_MFR_AMD		0x01
 #define NAND_MFR_ATO		0x9b
 #define NAND_MFR_EON		0x92
+/* ESMT and GigaDevice share the same manufacturer ID. */
 #define NAND_MFR_ESMT		0xc8
 #define NAND_MFR_FUJITSU	0x04
 #define NAND_MFR_HYNIX		0xad
diff --git a/drivers/mtd/nand/raw/nand_ids.c b/drivers/mtd/nand/raw/nand_ids.c
index 08707ce9d7c0..9b2dd246398f 100644
--- a/drivers/mtd/nand/raw/nand_ids.c
+++ b/drivers/mtd/nand/raw/nand_ids.c
@@ -185,7 +185,7 @@ static const struct nand_manufacturer_desc nand_manufacturer_descs[] = {
 	{NAND_MFR_AMD, "AMD/Spansion", &amd_nand_manuf_ops},
 	{NAND_MFR_ATO, "ATO"},
 	{NAND_MFR_EON, "Eon"},
-	{NAND_MFR_ESMT, "ESMT", &esmt_nand_manuf_ops},
+	{NAND_MFR_ESMT, "ESMT/GigaDevice", &esmt_nand_manuf_ops},
 	{NAND_MFR_FUJITSU, "Fujitsu"},
 	{NAND_MFR_HYNIX, "Hynix", &hynix_nand_manuf_ops},
 	{NAND_MFR_INTEL, "Intel"},

-- 
2.55.0

