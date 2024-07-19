From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 19 Jul 2024 16:08:13 +0800
Subject: [PATCH v3 5/6] arm64: dts: amlogic: t7: add ao secure node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-soc_info-v3-5-020a3b687c0c@amlogic.com>
References: <20240719-soc_info-v3-0-020a3b687c0c@amlogic.com>
In-Reply-To: <20240719-soc_info-v3-0-020a3b687c0c@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721376490; l=1056;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=X8apXJPtSL4pC+EPOExwu5CekUwHZ9o11FW6DgwjmrM=;
 b=3JFRpb+37yakNpqi576ecStgHlK3dSYpZKqSqVkN/MTunWTuIFGZ/JRJsibj7DnJ+vegL9RAb
 bJvhzMen/p8Dx/7ldGQpzIiEYGnVB3quKLVAHf0RXOlviF+abDl4GvI
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add node for board info registers, which allows getting SoC family and
board revision.

For example, with MESON_GX_SOCINFO config enabled we can get the
following information for board with Amlogic T7 SoC:
soc soc0: Amlogic T7 (A311D2) Revision 36:c (1:1) Detected.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index c23efc6c7ac0..ec743cad57db 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -194,6 +194,14 @@ uart_a: serial@78000 {
 				interrupts = <GIC_SPI 168 IRQ_TYPE_EDGE_RISING>;
 				status = "disabled";
 			};
+
+			sec_ao: ao-secure@10220 {
+				compatible = "amlogic,t7-ao-secure",
+					     "amlogic,meson-gx-ao-secure",
+					     "syscon";
+				reg = <0x0 0x10220 0x0 0x140>;
+				amlogic,has-chip-id;
+			};
 		};
 
 	};

-- 
2.37.1

