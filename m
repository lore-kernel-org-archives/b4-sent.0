From: Dirk Chen <dirkchen@amd.com>
Date: Mon, 02 Feb 2026 10:29:31 +0800
Subject: [PATCH] ARM: dts: aspeed: anacapa: Add retimer EEPROMs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260202-b4-anacapa-dts-fix-v1-1-20d4b0114854@amd.com>
X-B4-Tracking: v=1; b=H4sIAAoMgGkC/x2MQQqAMAwEvyI5G6hVFP2KeEhrqrnU0ooI4t8NX
 gZmYPeBwlm4wFQ9kPmSIkdUaeoK/E5xY5RVHayxvVGg65AieUqE61kwyI3WDCHwSK0zHnSYMmv
 +T+flfT8yIKM9ZAAAAA==
X-Change-ID: 20260202-b4-anacapa-dts-fix-207ffe9a3b0c
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Dirk Chen <dirkchen@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769999372; l=1234;
 i=dirkchen@amd.com; s=20260202; h=from:subject:message-id;
 bh=7UiIsc+JRhKInxcNGMi5RJgMeig8fwCF34V25zBzaew=;
 b=HGTsrHSELPFy//GaIT4xCbcD3IxgB5enkX4xOed+Zt76V75ZNZQ64nOSSHnJjSMBUOjfvCB/4
 hI4PMdUVGWHAtomTjdx/g4w4bDKOJ/GG9o7vnEZsj2t4I6+xPqEA2+p
X-Developer-Key: i=dirkchen@amd.com; a=ed25519;
 pk=NBIyLsVg/YYtGLruq9XLdLWx2PP/1MH4jDDQ1V+7wes=
X-Endpoint-Received: by B4 Relay for dirkchen@amd.com/20260202 with auth_id=622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Atmel 24C2048 EEPROMs on i2c0 and i2c1 to support retimer
configuration. Follow the same compatible string usage as the
Facebook Harma platform to maintain consistency across Meta boards.

Signed-off-by: Dirk Chen <dirkchen@amd.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 221af858cb6b..b8d248d99d7c 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -328,6 +328,12 @@ i2c0mux0ch3: i2c@3 {
 			#size-cells = <0>;
 		};
 	};
+
+	eeprom@50 {
+		compatible = "atmel,24c2048";
+		reg = <0x50>;
+		pagesize = <128>;
+	};
 };
 
 // R Bridge Board
@@ -362,6 +368,12 @@ i2c1mux0ch3: i2c@3 {
 			#size-cells = <0>;
 		};
 	};
+
+	eeprom@50 {
+		compatible = "atmel,24c2048";
+		reg = <0x50>;
+		pagesize = <128>;
+	};
 };
 
 // MB - E1.S

---
base-commit: 4c87cdd0328495759f6e9f9f4e1e53ef8032a76f
change-id: 20260202-b4-anacapa-dts-fix-207ffe9a3b0c

Best regards,
-- 
Dirk Chen <dirkchen@amd.com>

