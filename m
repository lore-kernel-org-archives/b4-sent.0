From: Colin Huang <u8813345@gmail.com>
Date: Thu, 13 Aug 2026 19:59:44 +0800
Subject: [PATCH v5 14/15] ARM: dts: aspeed: anacapa: Use default SPI2
 memory mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-anacapa-devlop-phase-devicetree-v5-14-c7058f63dc67@gmail.com>
References: <20260813-anacapa-devlop-phase-devicetree-v5-0-c7058f63dc67@gmail.com>
In-Reply-To: <20260813-anacapa-devlop-phase-devicetree-v5-0-c7058f63dc67@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786622378; l=819;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=oxTF20CYiA7RH6T7z/fDB4EwQ1KdT7fYEEX/g/uzaW4=;
 b=yqV5uqb6ufRzAE5RQBXJYWysUIhzgVy0VSJP+HK2eco3jzvaBlc5EzKqNhmEsySCR4W0wyfZJ
 +muB2m33F5VC6z+kLptDpOQkx5MBIr9Br537nLY+hjPowEzW6s4nKP+
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the board-specific SPI2 reg property override and rely on the
default SPI2 memory window definition provided by aspeed-g6.dtsi.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
index f27ec52f9d56..d613b5b9d6b0 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
@@ -1062,7 +1062,6 @@ &sgpiom0 {
 
 // BIOS Flash
 &spi2 {
-	reg = <0x1e631000 0xc4>, <0x50000000 0x8000000>;
 	pinctrl-0 = <&pinctrl_spi2_default>;
 
 	pinctrl-names = "default";

-- 
2.34.1

