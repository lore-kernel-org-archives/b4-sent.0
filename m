From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 28 Jan 2026 10:09:54 +0000
Subject: [PATCH] arm64: dts: amlogic: a4: fix pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260128-fix-a4-pinctl-node-v1-1-617a1f539902@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAHHgeWkC/x2MWwqAIBAArxL73UJt0esq0YfpVguhohGBdPekz
 4GZSRA5CEeYigSBb4nibIa6LEAfyu6MYjIDVdRVNQ24yYOqRS9WXydaZxg702+jpnFtSEEOfeB
 s/dN5ed8PqDHy92QAAAA=
X-Change-ID: 20260128-fix-a4-pinctl-node-6d7f9c29b32a
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769595003; l=1293;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=F6Np6Gg5OfDL8SOtdbBhRnTvyEqILZTAt6VZ6iphZjU=;
 b=klaiKJo6ZXYdkMttvJFCkjmYPGO+ViMwibRH3IvVKYi1pOexAtu5Fpu0DiJT/zW6MPW+LQJC5
 PWuoph2b+74A/QH2bae0AyNkycivBV6dCia29/RQ2iwwzlcxBF2gGuT
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix incorrect pinctrl device reference when adding GPIO to pinctrl device.

Fixes: e9bb91734871 ("arm64: dts: amlogic: a4: add pinctrl node")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Fix A4 pinctrl node.
---
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index fce45933fa28..6587e3578f8d 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -218,7 +218,7 @@ gpioao: gpio@4 {
 			reg-names = "gpio", "mux";
 			gpio-controller;
 			#gpio-cells = <2>;
-			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_AO<<8) 7>;
+			gpio-ranges = <&ao_pinctrl 0 (AMLOGIC_GPIO_AO<<8) 7>;
 		};
 
 		test_n: gpio@44 {
@@ -226,7 +226,7 @@ test_n: gpio@44 {
 			reg-names = "gpio";
 			gpio-controller;
 			#gpio-cells = <2>;
-			gpio-ranges = <&periphs_pinctrl 0 (AMLOGIC_GPIO_TEST_N<<8) 1>;
+			gpio-ranges = <&ao_pinctrl 0 (AMLOGIC_GPIO_TEST_N<<8) 1>;
 		};
 	};
 

---
base-commit: e3194dfb772304a1b7ca3bcfccacefec3468b7bf
change-id: 20260128-fix-a4-pinctl-node-6d7f9c29b32a

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

