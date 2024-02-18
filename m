From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 18 Feb 2024 20:02:51 +0800
Subject: [PATCH v2 2/3] arm64: dts: hi3798cv200: add GICH, GICV register
 space and irq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240218-cache-v2-2-1fd919e2bd3e@outlook.com>
References: <20240218-cache-v2-0-1fd919e2bd3e@outlook.com>
In-Reply-To: <20240218-cache-v2-0-1fd919e2bd3e@outlook.com>
To: Wei Xu <xuwei5@hisilicon.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, Alex Elder <elder@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708257770; l=1117;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=oWPOXVSM7W5vHY31kDr4p2HrgQkuCpZx2sc6S9SlCF8=;
 b=YbBBZa81olla9r1dJqBTLzU5eZwlr9EMPAU11UChDqur5df31Kx/+zKUl+9eMR6I2jiXr8mlW
 b4PZ90CnhK9BmpzF3yRdh+HkmJCb9f7ZfAsvKVslY2q6zD8eJ4GMr4D
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is needed by KVM to make use of VGIC code. Just like regular
GIC-400, PPI #9 is the hypervisor maintenance interrupt. It has been
verified.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
index d01023401d7e..fc64d2fa99eb 100644
--- a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
+++ b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
@@ -58,7 +58,11 @@ cpu@3 {
 	gic: interrupt-controller@f1001000 {
 		compatible = "arm,gic-400";
 		reg = <0x0 0xf1001000 0x0 0x1000>,  /* GICD */
-		      <0x0 0xf1002000 0x0 0x2000>;  /* GICC */
+		      <0x0 0xf1002000 0x0 0x2000>,  /* GICC */
+		      <0x0 0xf1004000 0x0 0x2000>,  /* GICH */
+		      <0x0 0xf1006000 0x0 0x2000>;  /* GICV */
+		interrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(4) |
+			      IRQ_TYPE_LEVEL_HIGH)>;
 		#address-cells = <0>;
 		#interrupt-cells = <3>;
 		interrupt-controller;

-- 
2.43.0

