From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 19 Feb 2024 23:05:26 +0800
Subject: [PATCH v3 1/3] arm64: dts: hi3798cv200: fix the size of GICR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240219-cache-v3-1-a33c57534ae9@outlook.com>
References: <20240219-cache-v3-0-a33c57534ae9@outlook.com>
In-Reply-To: <20240219-cache-v3-0-a33c57534ae9@outlook.com>
To: Wei Xu <xuwei5@hisilicon.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, Alex Elder <elder@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708355220; l=1236;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=Q7LcOT/VwpsuZcFlk8XRnwmi13g7rI7h0WTW2e9avFs=;
 b=Jm1sLBoWsNwRJnBJqT57uUsQ1DHPNPKwfkMsWU3hTpw3/doshoWyTEdH8NI4jO9bvXfuXAZ5F
 FGleHPqE4pEDExYWkqaZcbEFAOM4CmVWgzh11Fe/xVPEr+ime6GIurZ
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During boot, Linux kernel complains:

[    0.000000] GIC: GICv2 detected, but range too small and irqchip.gicv2_force_probe not set

This SoC is using a regular GIC-400 and the GICR space size should be
8KB rather than 256B.

With this patch:

[    0.000000] GIC: Using split EOI/Deactivate mode

So this should be the correct fix.

Fixes: 2f20182ed670 ("arm64: dts: hisilicon: add dts files for hi3798cv200-poplar board")
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
Cc: stable@vger.kernel.org
---
 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
index ed1b5a7a6067..d01023401d7e 100644
--- a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
+++ b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
@@ -58,7 +58,7 @@ cpu@3 {
 	gic: interrupt-controller@f1001000 {
 		compatible = "arm,gic-400";
 		reg = <0x0 0xf1001000 0x0 0x1000>,  /* GICD */
-		      <0x0 0xf1002000 0x0 0x100>;   /* GICC */
+		      <0x0 0xf1002000 0x0 0x2000>;  /* GICC */
 		#address-cells = <0>;
 		#interrupt-cells = <3>;
 		interrupt-controller;

-- 
2.43.0

