From: Colin Huang <u8813345@gmail.com>
Date: Tue, 25 Aug 2026 18:47:49 +0800
Subject: [PATCH v6 08/12] ARM: dts: aspeed: anacapa: Enable MCTP and FRU
 for NIC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-anacapa-devlop-phase-devicetree-v6-8-9059a2a279ce@gmail.com>
References: <20260825-anacapa-devlop-phase-devicetree-v6-0-9059a2a279ce@gmail.com>
In-Reply-To: <20260825-anacapa-devlop-phase-devicetree-v6-0-9059a2a279ce@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>, 
 Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787654905; l=3240;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=dOnAmtbd66IVx7oXtqFQ1g3XoTMO1Ryg0F0x9FVbMP8=;
 b=ftyDPTkjdoGzotF4l5iWYs6uhTqylEgD5qyrES/Ylqri27+Dso7FI2I0uqGRiBcqYUp1nMkgc
 Dw7Lg2km/n5BgNptYTxctfAUFsGd5PPJiJW0yhYnmlyaZzPlc0+/kUh
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Andy Chung <Andy.Chung@amd.com>

Add the mctp-controller property to enable frontend NIC management
via PLDM over MCTP.
Also add EEPROM device for NIC FRU and reorder the I2C virtual bus
index accroding to the system silkscreen index.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
 .../aspeed/aspeed-bmc-facebook-anacapa-evt2.dts    | 137 +++++++++++++++++++++
 1 file changed, 137 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts
index 7c641a79f63e..7fe8d279202a 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt2.dts
@@ -8,6 +8,25 @@ / {
 	model = "Facebook Anacapa BMC";
 };
 
+&{/aliases} {
+	i2c36 = &i2c11mux0ch5;
+	i2c37 = &i2c11mux0ch6;
+	i2c38 = &i2c11mux0ch7;
+	i2c39 = &i2c11mux0ch0;
+	i2c40 = &i2c11mux0ch1;
+	i2c41 = &i2c11mux0ch2;
+	i2c42 = &i2c11mux0ch3;
+	i2c43 = &i2c11mux0ch4;
+	i2c44 = &i2c10mux0ch1;
+	i2c45 = &i2c10mux0ch2;
+	i2c46 = &i2c10mux0ch3;
+	i2c47 = &i2c10mux0ch4;
+	i2c48 = &i2c10mux0ch5;
+	i2c49 = &i2c10mux0ch6;
+	i2c50 = &i2c10mux0ch7;
+	i2c51 = &i2c10mux0ch0;
+};
+
 // MB - PDB
 &i2c8 {
 	i2c-mux@72 {
@@ -56,6 +75,124 @@ eeprom@51 {
 	};
 };
 
+// R Bridge Board
+&i2c10 {
+	multi-master;
+
+	mctp@10 {
+		compatible = "mctp-i2c-controller";
+		reg = <(0x10 | I2C_OWN_SLAVE_ADDRESS)>;
+	};
+
+	i2c-mux@71 {
+		/delete-property/ i2c-mux-idle-disconnect;
+
+		i2c10mux0ch1: i2c@1 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+
+		i2c10mux0ch2: i2c@2 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+
+		i2c10mux0ch3: i2c@3 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+
+		i2c10mux0ch4: i2c@4 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+	};
+};
+
+// L Bridge Board
+&i2c11 {
+	multi-master;
+
+	mctp@10 {
+		compatible = "mctp-i2c-controller";
+		reg = <(0x10 | I2C_OWN_SLAVE_ADDRESS)>;
+	};
+
+	i2c-mux@71 {
+		/delete-property/ i2c-mux-idle-disconnect;
+
+		i2c11mux0ch0: i2c@0 {
+			mctp-controller;
+			// FE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+
+		i2c11mux0ch1: i2c@1 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+
+		i2c11mux0ch2: i2c@2 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+
+		i2c11mux0ch3: i2c@3 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+
+		i2c11mux0ch4: i2c@4 {
+			mctp-controller;
+			// BE NIC FRU
+
+			eeprom@50 {
+				compatible = "atmel,24c32";
+				reg = <0x50>;
+			};
+		};
+	};
+};
+
 // MB
 &i2c13 {
 	i2c-mux@70 {

-- 
2.34.1

