From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:31 +0200
Subject: [PATCH 13/19] thunderbolt: Add QUIRK_NO_DMA_PORT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-13-44bc9348683c@kernel.org>
References: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
In-Reply-To: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3244; i=sven@kernel.org;
 h=from:subject:message-id; bh=ys3MSPTh8sqC1O/yv08O/qeOshWA9L72ZznWjJevtX4=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCZFKJbWRpu7a9XZdn2duKzJSeVjsdFhs3m2/zbenb
 gnJSb/fUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjI35MM/4zbDoYaJr+eqLZE
 4xGPrfarjvYz4XGXFhklFluHfMrP+8zIMKHxub3n3VMNi/vTtk7SyZiuFVKR57d2i1KUYeA1Ged
 73AA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple Silicon machines load and update the host router firmware with a
separate, proprietary mechanism and have no DMA port. Add a quirk to
skip its initialization.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/nhi.h    |  1 +
 drivers/thunderbolt/switch.c | 10 ++++++----
 drivers/thunderbolt/tb.c     |  8 ++++++++
 drivers/thunderbolt/tb.h     |  2 ++
 4 files changed, 17 insertions(+), 4 deletions(-)

diff --git a/drivers/thunderbolt/nhi.h b/drivers/thunderbolt/nhi.h
index 670b48efeec5..c2d16ab6994e 100644
--- a/drivers/thunderbolt/nhi.h
+++ b/drivers/thunderbolt/nhi.h
@@ -168,6 +168,7 @@ struct tb_nhi_ops {
 #define QUIRK_AUTO_CLEAR_INT				BIT(0)
 #define QUIRK_E2E					BIT(1)
 #define QUIRK_RESET_DMA_ON_TEARDOWN			BIT(2)
+#define QUIRK_NO_DMA_PORT				BIT(3)
 
 /*
  * Minimal number of vectors when we use MSI-X. Two for control channel
diff --git a/drivers/thunderbolt/switch.c b/drivers/thunderbolt/switch.c
index 3f54a5ae56b0..ef267f40c103 100644
--- a/drivers/thunderbolt/switch.c
+++ b/drivers/thunderbolt/switch.c
@@ -3317,10 +3317,12 @@ int tb_switch_add(struct tb_switch *sw)
 	 * to the userspace. NVM can be accessed through DMA
 	 * configuration based mailbox.
 	 */
-	ret = tb_switch_add_dma_port(sw);
-	if (ret) {
-		dev_err(&sw->dev, "failed to add DMA port\n");
-		return ret;
+	if (!sw->no_dma_port) {
+		ret = tb_switch_add_dma_port(sw);
+		if (ret) {
+			dev_err(&sw->dev, "failed to add DMA port\n");
+			return ret;
+		}
 	}
 
 	ret = tb_switch_nvm_init(sw);
diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index 47753a5c0f2e..c43cdd2c2e2e 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -15,6 +15,7 @@
 #include "tb.h"
 #include "tb_regs.h"
 #include "tunnel.h"
+#include "nhi.h"
 
 #define TB_TIMEOUT		100	/* ms */
 #define TB_RELEASE_BW_TIMEOUT	10000	/* ms */
@@ -3036,6 +3037,13 @@ static int tb_start(struct tb *tb, bool reset)
 	/* All USB4 routers support runtime PM */
 	tb->root_switch->rpm = tb_switch_is_usb4(tb->root_switch);
 
+	/*
+	 * Apple Silicon machines have a separate, proprietary mechanism for
+	 * loading and updating firmware. Skip the DMA port initialization on
+	 * these machines.
+	 */
+	tb->root_switch->no_dma_port = tb->nhi->quirks & QUIRK_NO_DMA_PORT;
+
 	ret = tb_switch_configure(tb->root_switch);
 	if (ret) {
 		tb_switch_put(tb->root_switch);
diff --git a/drivers/thunderbolt/tb.h b/drivers/thunderbolt/tb.h
index 4373336d9425..0977cd690d7e 100644
--- a/drivers/thunderbolt/tb.h
+++ b/drivers/thunderbolt/tb.h
@@ -139,6 +139,7 @@ struct tb_switch_tmu {
  * @drom: DROM of the switch (%NULL if not found)
  * @nvm: Pointer to the NVM if the switch has one (%NULL otherwise)
  * @no_nvm_upgrade: Prevent NVM upgrade of this switch
+ * @no_dma_port: Prevent adding the DMA port of this switch
  * @safe_mode: The switch is in safe-mode
  * @boot: Whether the switch was already authorized on boot or not
  * @rpm: The switch supports runtime PM
@@ -194,6 +195,7 @@ struct tb_switch {
 	u8 *drom;
 	struct tb_nvm *nvm;
 	bool no_nvm_upgrade;
+	bool no_dma_port;
 	bool safe_mode;
 	bool boot;
 	bool rpm;

-- 
2.55.0

