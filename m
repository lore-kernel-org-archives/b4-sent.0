From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 19 Jan 2024 20:49:17 +0800
Subject: [PATCH] reset: reset-hisilicon: also handle #reset-cells = <2>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240119-rst-v1-1-894c88985f5a@outlook.com>
X-B4-Tracking: v=1; b=H4sIAMxvqmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0NL3aLiEl2DpGQLA0vzJAsT80QloMqCotS0zAqwKdGxtbUAsn+tFFU
 AAAA=
To: u-boot@lists.denx.de
Cc: Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705668557; l=1371;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=xdBog517xIp3ODBZpffzQFiYeYTTPeK84K24y7OXYd4=;
 b=CDLD3UbrtRppheSP7oKn3pv3H6J5Ce/xmkzn4jKRK1N0Fragon/JyuwysHPmPiREo067cEDg0
 cXViLvoqxblCO3XHWLorgzF3/WFID6v+59d1UQlcEUuYujPUoERTY5m
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's also valid to have #reset-cells = <2> while the third arg defaults
to ASSERT_SET.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/reset/reset-hisilicon.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/drivers/reset/reset-hisilicon.c b/drivers/reset/reset-hisilicon.c
index 8152cec227..85e02b296b 100644
--- a/drivers/reset/reset-hisilicon.c
+++ b/drivers/reset/reset-hisilicon.c
@@ -49,7 +49,18 @@ static int hisi_reset_assert(struct reset_ctl *rst)
 static int hisi_reset_of_xlate(struct reset_ctl *rst,
 			       struct ofnode_phandle_args *args)
 {
-	if (args->args_count != 3) {
+	unsigned long polarity;
+
+	switch (args->args_count) {
+	case 2:
+		polarity = ASSERT_SET;
+		break;
+
+	case 3:
+		polarity = args->args[2];
+		break;
+
+	default:
 		debug("Invalid args_count: %d\n", args->args_count);
 		return -EINVAL;
 	}
@@ -57,7 +68,7 @@ static int hisi_reset_of_xlate(struct reset_ctl *rst,
 	/* Use .data field as register offset and .id field as bit shift */
 	rst->data = args->args[0];
 	rst->id = args->args[1];
-	rst->polarity = args->args[2];
+	rst->polarity = polarity;
 
 	return 0;
 }

---
base-commit: f7cca7ccc5117eaafcc2bde91ad1bed6fee7cfc3
change-id: 20240119-rst-0bc8097b847a

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

