From: Maud Spierings <maud_spierings@hotmail.com>
Date: Mon, 20 Oct 2025 19:34:06 +0200
Subject: [PATCH v2] parted: add max option to mkpart <end>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251020-parted-v2-1-63b8490ec9f4@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAI1y9mgC/2XMQQ6CMBCF4auQWVszA1apK+9hWBQ6yiRCSds0G
 sLdrWxd/i8v3wqRg3CEa7VC4CxR/FyiPlQwjHZ+shJXGmqsNSEZtdiQ2Kke3bm56Ba5RSjnJfB
 D3jt070qPEpMPn93N9Fv/iEyKlGl61Ej9CZ25jT5NVl7HwU/Qbdv2Bd39dIKeAAAA
X-Change-ID: 20251019-parted-b0d637580e80
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760981648; l=3588;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=vKyxeMOFHKeRteYbOIinQ83si/JuCrpetNr2ni6B0BE=;
 b=JXc+B8SfltPukohjANtkXBvIsvyvG7SN27hVjRNiZsm3pJi0QXME/K1yQXSFLQTDi/qQ6qDK8
 WR6pGjpZAk/BgGC9mw95dZ5L5JJmlvaMY9HwXgxfNgHPwGxCy6pjugo
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the option to specify "max" as the end location, this will fill the
block device up to the end of its available space.

A secondary effect is that it is now possible to use two different size
units for start and end

mkpart root ext4 66MiB 3866111KiB

previously it would read 66MiB as 66KiB as it only used the last read
unit.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Changes in v2:
- Remove rounding down of the end point to the nearest MiB boundary
- remove the else if and make it the else continue to get rid of
  assignment in if condition.
- Link to v1: https://lore.kernel.org/r/20251019-parted-v1-1-93b0501b40d9@hotmail.com
---
 commands/parted.c | 55 +++++++++++++++++++++++++++++++++++--------------------
 1 file changed, 35 insertions(+), 20 deletions(-)

diff --git a/commands/parted.c b/commands/parted.c
index 7ec56da4c15f..f03dc37c05b3 100644
--- a/commands/parted.c
+++ b/commands/parted.c
@@ -138,6 +138,10 @@ static int do_mkpart(struct block_device *blk, int argc, char *argv[])
 	int ret;
 	uint64_t mult;
 
+	pdesc = pdesc_get(blk);
+	if (!pdesc)
+		return -EINVAL;
+
 	if (argc < 5) {
 		printf("Error: Missing required arguments\n");
 		return -EINVAL;
@@ -150,40 +154,50 @@ static int do_mkpart(struct block_device *blk, int argc, char *argv[])
 	if (ret)
 		return ret;
 
-	ret = parted_strtoull(argv[4], &end, &mult);
-	if (ret)
-		return ret;
-
 	if (!mult)
 		mult = gunit;
-
 	start *= mult;
-	end *= mult;
 
-	/* If not on sector boundaries move start up and end down */
+	/* If not on sector boundaries round start up */
 	start = ALIGN(start, SZ_1M);
-	end = ALIGN_DOWN(end, SZ_1M);
 
 	/* convert to LBA */
 	start >>= SECTOR_SHIFT;
-	end >>= SECTOR_SHIFT;
+
+	if (!strcmp(argv[4], "max")) {
+		/* gpt requires 34 blocks at the end */
+		if (pdesc->parser->type == filetype_gpt)
+			end = blk->num_blocks - 35;
+		else if (pdesc->parser->type == filetype_mbr)
+			end = blk->num_blocks - 1;
+		else
+			return -ENOSYS;
+	} else {
+		ret = parted_strtoull(argv[4], &end, &mult);
+		if (ret)
+			return ret;
+
+		if (!mult)
+			mult = gunit;
+		end *= mult;
+
+		/* convert to LBA */
+		end >>= SECTOR_SHIFT;
+
+		/*
+		 * When unit is >= KB then subtract one sector for user
+		 * convenience. It allows to start the next partition where the
+		 * previous ends
+		 */
+		if (mult >= 1000)
+			end -= 1;
+	}
 
 	if (end == start) {
 		printf("Error: After alignment the partition has zero size\n");
 		return -EINVAL;
 	}
 
-	/*
-	 * When unit is >= KB then substract one sector for user convenience.
-	 * It allows to start the next partition where the previous ends
-	 */
-	if (mult >= 1000)
-		end -= 1;
-
-	pdesc = pdesc_get(blk);
-	if (!pdesc)
-		return -EINVAL;
-
 	ret = partition_create(pdesc, name, fs_type, start, end);
 
 	if (!ret)
@@ -424,6 +438,7 @@ BAREBOX_CMD_HELP_TEXT("<type> must be \"gpt\" or \"msdos\"")
 BAREBOX_CMD_HELP_TEXT("<fstype> can be one of  \"ext2\", \"ext3\", \"ext4\", \"fat16\", \"fat32\" or \"bbenv\"")
 BAREBOX_CMD_HELP_TEXT("<name> for MBR partition tables can be one of \"primary\", \"extended\" or")
 BAREBOX_CMD_HELP_TEXT("\"logical\". For GPT this is a name string.")
+BAREBOX_CMD_HELP_TEXT("<end> can be \"max\" it will take all remaining space")
 BAREBOX_CMD_HELP_END
 
 BAREBOX_CMD_START(parted)

---
base-commit: 8defba1d0ab1aef9dd5d57710e18d0d02e2c48e2
change-id: 20251019-parted-b0d637580e80

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

