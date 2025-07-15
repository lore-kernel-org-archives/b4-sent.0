From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 15 Jul 2025 20:51:38 +0800
Subject: [PATCH 1/2] dt-bindings: clock: add video clock indices for
 Amlogic S4 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-add_video_clk-v1-1-40e7f633f361@amlogic.com>
References: <20250715-add_video_clk-v1-0-40e7f633f361@amlogic.com>
In-Reply-To: <20250715-add_video_clk-v1-0-40e7f633f361@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752583900; l=1212;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=LztxELd9EtqmjCHRSvnKXiDEtIhmTixy/0hdsbLfFOA=;
 b=H9D6zYFXC/H+ChDtNW3x0uSFhuScIdrRXaA1ArwghGEqWePsiq/3BLToknEoNOGIzsLvNoED7
 Ek24Wg8K0TNDNgnd9VqLJPVZuJUu7vagTAQu5PiiMFhgy7HYBtzljT5
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add indices for video encoder, demodulator and CVBS clocks.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 include/dt-bindings/clock/amlogic,s4-peripherals-clkc.h | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/include/dt-bindings/clock/amlogic,s4-peripherals-clkc.h b/include/dt-bindings/clock/amlogic,s4-peripherals-clkc.h
index 861a331963ac..a1cd22b25102 100644
--- a/include/dt-bindings/clock/amlogic,s4-peripherals-clkc.h
+++ b/include/dt-bindings/clock/amlogic,s4-peripherals-clkc.h
@@ -232,5 +232,19 @@
 #define CLKID_HDCP22_SKPCLK_SEL		222
 #define CLKID_HDCP22_SKPCLK_DIV		223
 #define CLKID_HDCP22_SKPCLK		224
+#define CLKID_CTS_ENCL_SEL		225
+#define CLKID_CTS_ENCL			226
+#define CLKID_LCD_AN_SEL		227
+#define CLKID_LCD_AN_PH2		228
+#define CLKID_LCD_AN_PH3		229
+#define CLKID_CDAC_SEL			230
+#define CLKID_CDAC_DIV			231
+#define CLKID_CDAC			232
+#define CLKID_DEMOD_CORE_SEL		233
+#define CLKID_DEMOD_CORE_DIV		234
+#define CLKID_DEMOD_CORE		235
+#define CLKID_ADC_EXTCLK_IN_SEL		236
+#define CLKID_ADC_EXTCLK_IN_DIV		237
+#define CLKID_ADC_EXTCLK_IN		238
 
 #endif /* _DT_BINDINGS_CLOCK_AMLOGIC_S4_PERIPHERALS_CLKC_H */

-- 
2.42.0

