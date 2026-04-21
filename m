From: Jian Hu <jian.hu@amlogic.com>
Date: Tue, 21 Apr 2026 16:17:43 +0800
Subject: [PATCH v3 3/4] arm64: dts: meson: a1: Add clk measure support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260421-clkmsr_a1_t7-v3-3-efc00b0f9e6b@amlogic.com>
References: <20260421-clkmsr_a1_t7-v3-0-efc00b0f9e6b@amlogic.com>
In-Reply-To: <20260421-clkmsr_a1_t7-v3-0-efc00b0f9e6b@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776759517; l=796;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=O86sT98wsFFOKZkjD097kQOtYoxBWLlc/HPpfUJkTMk=;
 b=8iw4mI0MTc1m3WzM4UlLTpcP2P1hOFu1li1dE6jCJdih91bUQAeoRGXl8dOfZhCkiY7Ub3oot
 OqcrvJcAnOBBm15G56BZ2MIHV6eDeptBa7s0m4DNqwU8P0RDVh8C6rD
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the clock measure device to the A1 SoC family.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/meson-a1.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-a1.dtsi b/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
index 348411411f3d..6f6a6145cba1 100644
--- a/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-a1.dtsi
@@ -576,6 +576,11 @@ saradc: adc@2c00 {
 				status = "disabled";
 			};
 
+			clock-measurer@3400 {
+				compatible = "amlogic,a1-clk-measure";
+				reg = <0x0 0x3400 0x0 0x1c>;
+			};
+
 			i2c1: i2c@5c00 {
 				compatible = "amlogic,meson-axg-i2c";
 				status = "disabled";

-- 
2.47.1

