From: Qinguang Xu <guang.cy2023@gmail.com>
Date: Tue, 20 Oct 2026 21:39:06 +0800
Subject: [PATCH] regmap: irq: fix incorrect index calculation for
 read_sub_irq_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-debug-v1-1-44e0491ede30@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyMD3ZTUpNJ0XbOk1FRTUzNji0RLQyWg2oKi1LTMCrA50bG1tQDoIvy
 tVwAAAA==
X-Change-ID: 20261020-debug-6bee55638a91
To: Mark Brown <broonie@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>
Cc: linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 Qinguang Xu <guang.cy2023@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792503607; l=1610;
 i=guang.cy2023@gmail.com; s=20261020; h=from:subject:message-id;
 bh=h/epT8PozJJSzYsR6YyQpeY/N08qpMA03/LtijdFBKU=;
 b=N/3MqOgQb9WGXlYuHe3je8J4Nun33kI8SPFWObRtxpeLnhwe3lVID8RzhMAkBE2xMpMPmjwY0
 +G1DTk/TrnLA+3Sh2SUuBPUsvq3JsrUCZGewiDRcoSd7gw1cr4bwnSy
X-Developer-Key: i=guang.cy2023@gmail.com; a=ed25519;
 pk=nBIKvk/kltcVDBLn+o4Bv1W0xE/m2VgIByF+uxYTYzk=
X-Endpoint-Received: by B4 Relay for guang.cy2023@gmail.com/20261020 with auth_id=1248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While working on a PMIC driver that utilizes num_main_regs > 1, this
issue was noticed. Currently, no in-tree driver sets `num_main_regs >
1`, so this bug has not been triggered in practice.

Pass the global index calculated with `i` instead of the local bit
offset `b` to read_sub_irq_data().

Fix an off-by-one error in the index bounds check.

This patch has been compile-tested only.

Signed-off-by: Qinguang Xu <guang.cy2023@gmail.com>
---
 drivers/base/regmap/regmap-irq.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/base/regmap/regmap-irq.c b/drivers/base/regmap/regmap-irq.c
index 99b55b105..e151c6222 100644
--- a/drivers/base/regmap/regmap-irq.c
+++ b/drivers/base/regmap/regmap-irq.c
@@ -398,14 +398,14 @@ static int read_irq_data(struct regmap_irq_chip_data *data)
 
 		/* Read sub registers with active IRQs */
 		for (i = 0; i < chip->num_main_regs; i++) {
-			unsigned int b;
+			unsigned int b, index;
 			const unsigned long mreg = data->main_status_buf[i];
 
 			for_each_set_bit(b, &mreg, map->format.val_bytes * 8) {
-				if (i * map->format.val_bytes * 8 + b >
-				    max_main_bits)
+				index = i * map->format.val_bytes * 8 + b;
+				if (index >= max_main_bits)
 					break;
-				ret = read_sub_irq_data(data, b);
+				ret = read_sub_irq_data(data, index);
 
 				if (ret != 0) {
 					dev_err(map->dev, "Failed to read IRQ status %d\n", ret);

---
base-commit: 4056b3c9d3c92ea45955641dbafeb9b960e146ef
change-id: 20261020-debug-6bee55638a91

Best regards,
-- 
Qinguang Xu <guang.cy2023@gmail.com>

