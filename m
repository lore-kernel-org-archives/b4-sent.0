From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sun, 19 Oct 2025 17:07:06 +0200
Subject: [PATCH] parted: add max option to mkpart <end>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251019-parted-v1-1-93b0501b40d9@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAJn+9GgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDA0NL3YLEopLUFN0kgxQzY3NTC4NUCwMloOKCotS0zAqwQdGxtbUAumA
 11VgAAAA=
X-Change-ID: 20251019-parted-b0d637580e80
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760889551; l=4234;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=zwCyK/H57AcW4GRaqumO/cCqsSvtqE+QFRdZGe7QVtY=;
 b=Cq0wrdXfV8pKG59DgQZXsq2sdKKXiQMzT81p9XkBjc/NgTKF8WPZFlsTriKrgGfAPvFWNtRYf
 B4dmktAzqP0CquYjQ57cuVy/iFhILNeDtGvjq9cob2mbggFSh3OZhq4
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
At first it was considered to make <end> an optional argument. But this
would make chaining parted subcommands very difficult to manage.
Therefore I chose to make "max" an option so this can still be done like
so:

parted /dev/mmc0 mklabel gpt mkpart env bbenv 1MiB 2MiB mkpart boot fat32 2MiB 66MiB mkpart root ext4 66MiB max print

I get a checkpatch error about assignment in an if statement, the issue
is that there is an error print in parted_strtoull(), so if it checks
for a regular value but it is "max" it will print an error even though
there is none.

removing that print and adding it to every place where it is used seems
excessive too. What would be a good alternative approach?

Another option I have considered is making end=0 mean fill to the end,
if that is preferred I will make it so in v2
---
 commands/parted.c | 56 +++++++++++++++++++++++++++++++++++--------------------
 1 file changed, 36 insertions(+), 20 deletions(-)

diff --git a/commands/parted.c b/commands/parted.c
index 7ec56da4c15f..0e858eb881ba 100644
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
@@ -150,40 +154,51 @@ static int do_mkpart(struct block_device *blk, int argc, char *argv[])
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
+	} else if (!(ret = parted_strtoull(argv[4], &end, &mult))) {
+		if (!mult)
+			mult = gunit;
+		end *= mult;
+
+		/* If not on sector boundaries round end down */
+		end = ALIGN_DOWN(end, SZ_1M);
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
+	} else {
+		return ret;
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
@@ -424,6 +439,7 @@ BAREBOX_CMD_HELP_TEXT("<type> must be \"gpt\" or \"msdos\"")
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

