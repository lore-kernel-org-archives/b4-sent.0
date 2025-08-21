From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:38:59 +0000
Subject: [PATCH RFC 07/22] usb: dwc3: apple: Adjust vendor-specific
 registers during init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-7-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2771; i=sven@kernel.org;
 h=from:subject:message-id; bh=Ikp6czp+quI9KYT9CWH9WFMemYOvMSa7Gr19hm1ueGQ=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy2xVS+teCv0fd52+62njLwutKT41zZ+O9/bz75wlvL
 pgvVt/dUcrCIMbBICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjI1B5GhjadZ9FrY78wRmp7
 NX++XLy80071lkXGivInUwP1uPbLRDL8T9LQdmuR5mrdu8jPKO/k4vYE4eU37k1duEylI+kKj+o
 NFgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

When tracing Apple's dwc3 driver under our hypervisor and comparing its
MMIO access with their kernel debug output these vendor-specific
registers have been identified. We don't know exactly what these do
or why they are required but without changing these parameters sometimes
USB3 devices don't work or take an additional 5 seconds to be recognized.

Signed-off-by: Hector Martin <marcan@marcan.st>
Co-developed-by: Sven Peter <sven@kernel.org>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/dwc3/core.c | 17 +++++++++++++++++
 drivers/usb/dwc3/core.h | 18 ++++++++++++++++++
 2 files changed, 35 insertions(+)

diff --git a/drivers/usb/dwc3/core.c b/drivers/usb/dwc3/core.c
index f8013ba2bdc22fa5e719df0841b12b84d9465b62..e018e80778cf39a9981d438c7e54534b26cddf63 100644
--- a/drivers/usb/dwc3/core.c
+++ b/drivers/usb/dwc3/core.c
@@ -1366,6 +1366,23 @@ static int dwc3_core_init(struct dwc3 *dwc)
 	 */
 	dwc3_writel(dwc->regs, DWC3_GUID, LINUX_VERSION_CODE);
 
+	/* Apply Apple quirks */
+	if (of_device_is_compatible(dwc->dev->of_node, "apple,t8103-dwc3")) {
+		dwc3_writel(dwc->regs,
+			    APPLE_DWC3_CIO_LFPS_OFFSET,
+			    APPLE_DWC3_CIO_LFPS_OFFSET_VALUE);
+		dwc3_writel(dwc->regs,
+			    APPLE_DWC3_CIO_BW_NGT_OFFSET,
+			    APPLE_DWC3_CIO_BW_NGT_OFFSET_VALUE);
+
+		u32 link_timer = dwc3_readl(dwc->regs, APPLE_DWC3_CIO_LINK_TIMER);
+
+		link_timer &= ~APPLE_DWC3_CIO_PENDING_HP_TIMER;
+		link_timer |= FIELD_PREP(APPLE_DWC3_CIO_PENDING_HP_TIMER,
+					 APPLE_DWC3_CIO_PENDING_HP_TIMER_VALUE);
+		dwc3_writel(dwc->regs, APPLE_DWC3_CIO_LINK_TIMER, link_timer);
+	}
+
 	ret = dwc3_phy_setup(dwc);
 	if (ret)
 		return ret;
diff --git a/drivers/usb/dwc3/core.h b/drivers/usb/dwc3/core.h
index 98e748cc348dfd9de1962c93fcf9f6a6690c2388..1caa46ca8b2ffb74dd3e58b174122e8f8216dd48 100644
--- a/drivers/usb/dwc3/core.h
+++ b/drivers/usb/dwc3/core.h
@@ -181,6 +181,24 @@
 
 #define DWC3_LLUCTL(n)		(0xd024 + ((n) * 0x80))
 
+/*
+ * Apple Silicon dwc3 vendor-specific registers
+ *
+ * These registers were identified by tracing XNU's memory access patterns
+ * and correlating them with debug output over serial to determine their names.
+ * We don't exactly know what these do but without these USB3 devices sometimes
+ * don't work.
+ */
+#define APPLE_DWC3_CIO_LFPS_OFFSET 0xcd38
+#define APPLE_DWC3_CIO_LFPS_OFFSET_VALUE 0xf800f80
+
+#define APPLE_DWC3_CIO_BW_NGT_OFFSET 0xcd3c
+#define APPLE_DWC3_CIO_BW_NGT_OFFSET_VALUE 0xfc00fc0
+
+#define APPLE_DWC3_CIO_LINK_TIMER 0xcd40
+#define APPLE_DWC3_CIO_PENDING_HP_TIMER GENMASK(23, 16)
+#define APPLE_DWC3_CIO_PENDING_HP_TIMER_VALUE 0x14
+
 /* Bit fields */
 
 /* Global SoC Bus Configuration INCRx Register 0 */

-- 
2.34.1

