From: Colin Huang <u8813345@gmail.com>
Date: Wed, 05 Aug 2026 21:02:40 +0800
Subject: [PATCH v4 12/12] ARM: dts: aspeed: anacapa: Add SPI flash VCC
 supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-anacapa-devlop-phase-devicetree-v4-12-5d67e0efa6c5@gmail.com>
References: <20260805-anacapa-devlop-phase-devicetree-v4-0-5d67e0efa6c5@gmail.com>
In-Reply-To: <20260805-anacapa-devlop-phase-devicetree-v4-0-5d67e0efa6c5@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>, 
 Rex Fu <rex.fu.amd@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785934963; l=941;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=f6LU0FAv4z223NfwbW5+xtWf2s69Q4QEuw+6jPL4YpI=;
 b=GU4HitdnZN9sIeaoEOIxc65OCZhYrjGp2dE2uozcgTcLXfDoR3GiEE+rtDALj7McAzfnsWjol
 g0HDu9Sad81Bonn1sgWxibVjHcRfneq+glygtwO4gZYOXQaVxuvb6zd
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Rex Fu <rex.fu.amd@gmail.com>

Specify the 3.3 V auxiliary rail as the SPI flash VCC supply to
avoid using the dummy regulator during device initialization.

Signed-off-by: Rex Fu <rex.fu.amd@gmail.com>
---
 .../boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts
index f913fa3f622d..cb4b815f1803 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts
@@ -27,6 +27,22 @@ / {
 	i2c51 = &i2c10mux0ch0;
 };
 
+&fmc {
+	flash@0 {
+		vcc-supply = <&p3v3_bmc_aux>;
+	};
+	flash@1 {
+		vcc-supply = <&p3v3_bmc_aux>;
+	};
+};
+
+// BIOS Flash
+&spi2 {
+	flash@0 {
+		vcc-supply = <&p3v3_bmc_aux>;
+	};
+};
+
 // MB - PDB
 &i2c8 {
 	i2c-mux@72 {

-- 
2.34.1

