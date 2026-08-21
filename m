From: Sven Peter <sven@kernel.org>
Date: Fri, 21 Aug 2026 15:50:28 +0200
Subject: [PATCH 2/3] phy: apple: atc: Factor out the PIPE mux sequence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-atcphy-usb4-v1-2-45c0b741e0c0@kernel.org>
References: <20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org>
In-Reply-To: <20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4042; i=sven@kernel.org;
 h=from:subject:message-id; bh=4jAaIiXyX7A+vKSBPBQthDtjH8uCrqGssc0AUrXmwpg=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZH+DKuB+oG2UUW35mElVkmWbqs+iXDM3fj9fDQ37uv+
 ly0b93TUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZhIwjlGhlXWluLskgLOt9Mt
 biV2lCx6q3jgvc8Mgc/LP/QrFTB92cTwT8nvyoNc4+rvdWte2zy6dsv7+q9tSgmmJm4cu+Z03FF
 z5QUA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This sequence is already used in three places and we're about to add a
fourth copy so let's factor it out to a helper. No functional change.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/phy/apple/atc.c | 46 +++++++++++++++++++---------------------------
 1 file changed, 19 insertions(+), 27 deletions(-)

diff --git a/drivers/phy/apple/atc.c b/drivers/phy/apple/atc.c
index a3162f25e6cd..96158d348656 100644
--- a/drivers/phy/apple/atc.c
+++ b/drivers/phy/apple/atc.c
@@ -972,6 +972,19 @@ static int atcphy_pipehandler_check(struct apple_atcphy *atcphy)
 	return 0;
 }
 
+static void atcphy_pipehandler_set_mux(struct apple_atcphy *atcphy, u32 data, u32 clk)
+{
+	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
+	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, PIPEHANDLER_MUX_CTRL_CLK_OFF));
+	udelay(10);
+	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_DATA,
+	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_DATA, data));
+	udelay(10);
+	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
+	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, clk));
+	udelay(10);
+}
+
 static int atcphy_configure_pipehandler_usb3(struct apple_atcphy *atcphy, bool host)
 {
 	int ret;
@@ -1054,15 +1067,8 @@ static int atcphy_configure_pipehandler_usb3(struct apple_atcphy *atcphy, bool h
 	}
 
 	/* Configure PIPE mux to USB3 PHY */
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, PIPEHANDLER_MUX_CTRL_CLK_OFF));
-	udelay(10);
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_DATA,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_DATA, PIPEHANDLER_MUX_CTRL_DATA_USB3));
-	udelay(10);
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, PIPEHANDLER_MUX_CTRL_CLK_USB3));
-	udelay(10);
+	atcphy_pipehandler_set_mux(atcphy, PIPEHANDLER_MUX_CTRL_DATA_USB3,
+				   PIPEHANDLER_MUX_CTRL_CLK_USB3);
 
 	/* Remove link detection override */
 	clear32(atcphy->regs.pipehandler + PIPEHANDLER_OVERRIDE, PIPEHANDLER_OVERRIDE_RXVALID);
@@ -1097,15 +1103,8 @@ static int atcphy_configure_pipehandler_dummy(struct apple_atcphy *atcphy)
 		dev_warn(atcphy->dev, "Failed to lock pipehandler");
 
 	/* Switch to dummy PHY */
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, PIPEHANDLER_MUX_CTRL_CLK_OFF));
-	udelay(10);
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_DATA,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_DATA, PIPEHANDLER_MUX_CTRL_DATA_DUMMY));
-	udelay(10);
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, PIPEHANDLER_MUX_CTRL_CLK_DUMMY));
-	udelay(10);
+	atcphy_pipehandler_set_mux(atcphy, PIPEHANDLER_MUX_CTRL_DATA_DUMMY,
+				   PIPEHANDLER_MUX_CTRL_CLK_DUMMY);
 
 	ret = atcphy_pipehandler_unlock(atcphy);
 	if (ret)
@@ -1149,15 +1148,8 @@ static void atcphy_setup_pipehandler(struct apple_atcphy *atcphy)
 {
 	lockdep_assert_held(&atcphy->lock);
 
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, PIPEHANDLER_MUX_CTRL_CLK_OFF));
-	udelay(10);
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_DATA,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_DATA, PIPEHANDLER_MUX_CTRL_DATA_DUMMY));
-	udelay(10);
-	mask32(atcphy->regs.pipehandler + PIPEHANDLER_MUX_CTRL, PIPEHANDLER_MUX_CTRL_CLK,
-	       FIELD_PREP(PIPEHANDLER_MUX_CTRL_CLK, PIPEHANDLER_MUX_CTRL_CLK_DUMMY));
-	udelay(10);
+	atcphy_pipehandler_set_mux(atcphy, PIPEHANDLER_MUX_CTRL_DATA_DUMMY,
+				   PIPEHANDLER_MUX_CTRL_CLK_DUMMY);
 }
 
 static void atcphy_configure_lanes(struct apple_atcphy *atcphy, enum atcphy_mode mode)

-- 
2.55.0

