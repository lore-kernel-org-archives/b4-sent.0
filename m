From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 11 Sep 2026 16:28:37 +0800
Subject: [PATCH 10/10] arm64: dts: amlogic: a9: Add clk-measure controller
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-more-socs-to-support-clk_measure-v1-10-940e269aa52f@amlogic.com>
References: <20260911-more-socs-to-support-clk_measure-v1-0-940e269aa52f@amlogic.com>
In-Reply-To: <20260911-more-socs-to-support-clk_measure-v1-0-940e269aa52f@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789115329; l=796;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=4DgrEoOMoCExjYXex82UD7PxEvK6o2H5kIyRyw8MyZw=;
 b=QAIblCVinkXyTUiFlM1L93hjc1ME8nF9bCDbxdu2+xRWd81XUrv+cNkPMFLuMHCoGKOruwAxh
 DdY4BtQWr2MCHv04gvadU0BnSbG0rKJv+EfA0DQty+ZTlyNrvvKQKAZ
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the clk-measure controller node for A9 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
index b0e0fadeed82..91f4cf319b0d 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi
@@ -185,6 +185,11 @@ gpio_intc: interrupt-controller@4080 {
 				amlogic,channel-interrupts =
 					<10 11 12 13 14 15 16 17 18 19 20 21>;
 			};
+
+			clk_msr: clock-measure@48000 {
+				compatible = "amlogic,a9-clk-measure";
+				reg = <0x0 0x48000 0x0 0x1c>;
+			};
 		};
 
 		gic: interrupt-controller@ff800000 {

-- 
2.42.0

