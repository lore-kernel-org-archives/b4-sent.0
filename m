From: Carl Lee <carl.lee@amd.com>
Date: Mon, 09 Mar 2026 11:29:27 +0800
Subject: [PATCH 1/2] ARM: dts: aspeed: anacapa: Add eeprom device node for
 PRoT module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v1-1-45092310e0e6@amd.com>
References: <20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v1-0-45092310e0e6@amd.com>
In-Reply-To: <20260309-arm-dts-aspeed-anacapa-add-eeprom-device-v1-0-45092310e0e6@amd.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 carl.lee@amd.com, peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773026981; l=712;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=4aUo+I25yKcWkfZ/hlkVpDZQt+CsSEqAbr9PaSDqHsg=;
 b=3tAsCSbsPpsPhvfGTXlpzgPTJPk7d61OGjUrgblTid5E+Kh1SZMxz/XNk3I6A/r4SM/0xmf6s
 MgaiyyjUEsBAA5/RaDvyLlXQywZtYW5oU5EX5TosmnWHVXjSE5zf2tq
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add eeprom device node for PRot module FRU.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 2cb7bd128d24..680108b00664 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -586,6 +586,11 @@ eeprom@50 {
 		reg = <0x50>;
 	};
 
+	eeprom@51 {
+		compatible = "atmel,24c128";
+		reg = <0x51>;
+	};
+
 	// BSM FRU
 	eeprom@56 {
 		compatible = "atmel,24c64";

-- 
2.34.1

