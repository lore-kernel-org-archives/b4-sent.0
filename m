From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 17 Feb 2024 20:52:06 +0800
Subject: [PATCH RFC v2 1/5] dt-bindings: clock: histb-clock: Add missing
 common clock and Hi3798MV200 specific clock definition
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240217-clk-mv200-v2-1-b782e4eb66f7@outlook.com>
References: <20240217-clk-mv200-v2-0-b782e4eb66f7@outlook.com>
In-Reply-To: <20240217-clk-mv200-v2-0-b782e4eb66f7@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708174332; l=1498;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=tAwhkwf2RTqZatW50V1J+QSR6rpA9D5O9tBXY261zlg=;
 b=Wd4NvzYkBjaJB8dBpsrrkE8Gp7ildNtAqBwU4yBYpdyeqle9YokQaZBaZsx2cDuJ8kNaJQ231
 adt6aXJIFTKB6GQJn8m4LtiU6fz/9iFOtuSNY1AXpwKDZvI8/AJEzYp
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the datasheet, some clocks are missing, add their
definitions first.

Some aliases for hi3798mv200 are also introduced.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 include/dt-bindings/clock/histb-clock.h | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/include/dt-bindings/clock/histb-clock.h b/include/dt-bindings/clock/histb-clock.h
index e64e5770ada6..68a53053586a 100644
--- a/include/dt-bindings/clock/histb-clock.h
+++ b/include/dt-bindings/clock/histb-clock.h
@@ -58,6 +58,27 @@
 #define HISTB_USB3_UTMI_CLK1		48
 #define HISTB_USB3_PIPE_CLK1		49
 #define HISTB_USB3_SUSPEND_CLK1		50
+#define HISTB_SDIO1_BIU_CLK		51
+#define HISTB_SDIO1_CIU_CLK		52
+#define HISTB_SDIO1_DRV_CLK		53
+#define HISTB_SDIO1_SAMPLE_CLK		54
+#define HISTB_ETH0_PHY_CLK		55
+#define HISTB_ETH1_PHY_CLK		56
+#define HISTB_WDG0_CLK			57
+#define HISTB_USB2_UTMI0_CLK		HISTB_USB2_UTMI_CLK
+#define HISTB_USB2_UTMI1_CLK		58
+#define HISTB_USB3_REF_CLK		59
+#define HISTB_USB3_GM_CLK		60
+#define HISTB_USB3_GS_CLK		61
+
+/* Hi3798MV200 specific clocks */
+
+// reuse clocks of histb
+#define HI3798MV200_GMAC_CLK		HISTB_ETH0_MAC_CLK
+#define HI3798MV200_GMACIF_CLK		HISTB_ETH0_MACIF_CLK
+#define HI3798MV200_FEMAC_CLK		HISTB_ETH1_MAC_CLK
+#define HI3798MV200_FEMACIF_CLK		HISTB_ETH1_MACIF_CLK
+#define HI3798MV200_FEPHY_CLK		HISTB_ETH1_PHY_CLK
 
 /* clocks provided by mcu CRG */
 #define HISTB_MCE_CLK			1

-- 
2.43.0

