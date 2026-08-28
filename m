From: Dirk Chen <dirkchen@amd.com>
Date: Fri, 28 Aug 2026 15:35:38 +0800
Subject: [PATCH] ARM: dts: aspeed: anacapa: Add MCTP I2C controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-anacapa-dts-amc-v1-1-463eb4e6a6a2@amd.com>
X-B4-Tracking: v=1; b=H4sIAEk6kWoC/x3MPQqAMAxA4atIZgO2hfpzFXEINWoGa2lEBPHuF
 sdveO8B5SysMFQPZL5E5YgFpq4gbBRXRpmLwTbWN53tkCIFSoTzqUh7QN8aG9reO14clCplXuT
 +j+P0vh9XFmTzYQAAAA==
X-Change-ID: 20260828-anacapa-dts-amc-6712c7963ef3
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>, 
 Ryan Chen <ryan_chen@aspeedtech.com>, 
 Billy Tsai <billy_tsai@aspeedtech.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Dirk Chen <dirkchen@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787902540; l=1212;
 i=dirkchen@amd.com; s=20260202; h=from:subject:message-id;
 bh=rEGeEm+ATZyoe3HxKSYL2gspIoEHBpWwgs2ytKBM6Z4=;
 b=Z63sFH/O7K+hj/ourvWsfKtVprO2gAFZc2jSHH6Tbxnbat8MpVQlRfpYi3XVYZFUWaSrvasBs
 +1b7UiNVonCDvhTqDRb4Ig/k6pcCe5oU0prhRBDgXib5zdgVH7BKUkW
X-Developer-Key: i=dirkchen@amd.com; a=ed25519;
 pk=NBIyLsVg/YYtGLruq9XLdLWx2PP/1MH4jDDQ1V+7wes=
X-Endpoint-Received: by B4 Relay for dirkchen@amd.com/20260202 with auth_id=622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Facebook Anacapa BMC uses I2C5 as an MCTP (Management Component
Transport Protocol) bus. This patch enables the controller by
adding the mctp-i2c-controller node under I2C5, with multi-master
support.

Signed-off-by: Dirk Chen <dirkchen@amd.com>
---
The Facebook Anacapa platform uses I2C5 as an MCTP (Management
Component Transport Protocol) bus for communication with the AMC.
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 1fddf3a5d138..6073a643ea80 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -433,6 +433,14 @@ i2c4mux0ch7: i2c@7 {
 // AMC
 &i2c5 {
 	status = "okay";
+
+	mctp-controller;
+	multi-master;
+
+	mctp@10 {
+		compatible = "mctp-i2c-controller";
+		reg = <(0x10 | I2C_OWN_SLAVE_ADDRESS)>;
+	};
 };
 
 // MB

---
base-commit: 3d83758432b5e6ed9507500a57efb0f3af41ee7d
change-id: 20260828-anacapa-dts-amc-6712c7963ef3

Best regards,
-- 
Dirk Chen <dirkchen@amd.com>

