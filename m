From: Sven Peter <sven@kernel.org>
Date: Fri, 21 Aug 2026 15:50:29 +0200
Subject: [PATCH 3/3] phy: apple: atc: Implement the USB4 pipehandler state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-atcphy-usb4-v1-3-45c0b741e0c0@kernel.org>
References: <20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org>
In-Reply-To: <20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2592; i=sven@kernel.org;
 h=from:subject:message-id; bh=WrxF+hzknbWy6eCuGGX+A/+N5AW7fUPL2sZ1KI+FggQ=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZH+HLe+IxdyrffM3xjmi3YIcB+Nfa6d4LOU5O0Bp7CM
 v6eOIuOUhYGMS4GWTFFlu377U2fPHwjuHTTpfcwc1iZQIYwcHEKwESu3WZkmDDt7KTCF9O+rfRm
 U37kuvlyb4/eG4UzzhebXjltPf0tIIbhv6dIw76pT2LCiva8NL/+s7jsyjXr203+Vp5Obw4Yti2
 9xQAA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

USB3 tunneled via USB4 requires dwc3's PIPE interface to be switched to
the USB4 NHI which will take care of the tunneling. Add the required
bringup sequence such that USB3 tunnels work once the USB4 NHI is
upstream.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/phy/apple/atc.c | 41 +++++++++++++++++++++++++++++++++++++----
 1 file changed, 37 insertions(+), 4 deletions(-)

diff --git a/drivers/phy/apple/atc.c b/drivers/phy/apple/atc.c
index 96158d348656..613bcd0ae886 100644
--- a/drivers/phy/apple/atc.c
+++ b/drivers/phy/apple/atc.c
@@ -1084,6 +1084,41 @@ static int atcphy_configure_pipehandler_usb3(struct apple_atcphy *atcphy, bool h
 	return 0;
 }
 
+static int atcphy_configure_pipehandler_usb4(struct apple_atcphy *atcphy)
+{
+	int ret;
+
+	ret = atcphy_pipehandler_check(atcphy);
+	if (ret)
+		return ret;
+
+	/* Force disable link detection */
+	clear32(atcphy->regs.pipehandler + PIPEHANDLER_OVERRIDE_VALUES,
+		PIPEHANDLER_OVERRIDE_VAL_RXDETECT0 | PIPEHANDLER_OVERRIDE_VAL_RXDETECT1);
+	set32(atcphy->regs.pipehandler + PIPEHANDLER_OVERRIDE, PIPEHANDLER_OVERRIDE_RXVALID);
+	set32(atcphy->regs.pipehandler + PIPEHANDLER_OVERRIDE, PIPEHANDLER_OVERRIDE_RXDETECT);
+
+	ret = atcphy_pipehandler_lock(atcphy);
+	if (ret) {
+		dev_err(atcphy->dev, "Failed to lock pipehandler\n");
+		return ret;
+	}
+
+	/* Configure PIPE mux to the USB4/Thunderbolt controller */
+	atcphy_pipehandler_set_mux(atcphy, PIPEHANDLER_MUX_CTRL_DATA_USB4,
+				   PIPEHANDLER_MUX_CTRL_CLK_USB4);
+
+	/* Remove link detection override */
+	clear32(atcphy->regs.pipehandler + PIPEHANDLER_OVERRIDE, PIPEHANDLER_OVERRIDE_RXVALID);
+	clear32(atcphy->regs.pipehandler + PIPEHANDLER_OVERRIDE, PIPEHANDLER_OVERRIDE_RXDETECT);
+
+	ret = atcphy_pipehandler_unlock(atcphy);
+	if (ret)
+		dev_warn(atcphy->dev, "Failed to unlock pipehandler\n");
+
+	return 0;
+}
+
 static int atcphy_configure_pipehandler_dummy(struct apple_atcphy *atcphy)
 {
 	int ret;
@@ -1130,10 +1165,8 @@ static int atcphy_configure_pipehandler(struct apple_atcphy *atcphy, bool host)
 		atcphy->pipehandler_up = true;
 		break;
 	case ATCPHY_PIPEHANDLER_STATE_USB4:
-		dev_warn(atcphy->dev,
-			 "ATCPHY_PIPEHANDLER_STATE_USB4 not implemented; falling back to USB2\n");
-		ret = atcphy_configure_pipehandler_dummy(atcphy);
-		atcphy->pipehandler_up = false;
+		ret = atcphy_configure_pipehandler_usb4(atcphy);
+		atcphy->pipehandler_up = true;
 		break;
 	case ATCPHY_PIPEHANDLER_STATE_DUMMY:
 		ret = atcphy_configure_pipehandler_dummy(atcphy);

-- 
2.55.0

