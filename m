From: Manojkiran Eda <manojkiran.eda@gmail.com>
Date: Wed, 18 Sep 2024 14:50:03 +0530
Subject: [PATCH v2] ARM: dts: aspeed: Enable PECI and LPC snoop for IBM
 System1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-dts-aspeed-system1-peci-snoop-v2-1-2d4d17403670@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEKb6mYC/43NTQ6CMBCG4auQWTuGlp+qK+9hWJQywCRCmw4hE
 sLdrZzA5fMt3m8Hocgk8Mh2iLSysJ8T9CUDN9p5IOQuGXSuy/yuDHaLoJVA1KFsstCkMJBjlNn
 7gEZXzuR9actbBakRIvX8OfuvJnlkWXzczrtV/dZ/y6tChe29Nn1b2NoU1XOYLL+vzk/QHMfxB
 WL1jDLKAAAA
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Manojkiran Eda <manojkiran.eda@gmail.com>, 
 Ninad Palsule <ninad@linux.ibm.com>, openbmc@lists.ozlabs.org, 
 Eddie James <eajames@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726651208; l=2124;
 i=manojkiran.eda@gmail.com; s=20240917; h=from:subject:message-id;
 bh=PhsAWX7PZUt4OM1Bw10bIDsLdGTH2xpjWLavU7+Q4Tk=;
 b=czWKIuxWc7LaxglC3n9wJmLebajDF5jrdBsRa+IlENMLoNzE6kVM3/qJqWPjuB3Y/egwdDuqB
 JNNjTtL1XS5BICAZswrBb/1tOEriGVb3/1DQfw2KkhL3/sE8CpMpgrM
X-Developer-Key: i=manojkiran.eda@gmail.com; a=ed25519;
 pk=DhQ/NRPeyE1WOxUmafF9Oy8LLco0c8CCeTN+Ef6q6Ts=
X-Endpoint-Received: by B4 Relay for manojkiran.eda@gmail.com/20240917 with auth_id=215
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch enables the PECI interface and configures the LPC Snoop for
ports 0x80 and 0x81 in the ASPEED BMC for IBM System1.

Signed-off-by: Manojkiran Eda <manojkiran.eda@gmail.com>
---
This patch enables PECI and LPC snoop functionality on the IBM System1
BMC in the device tree.

The following changes have been made:

1. Enabled the PECI controller (peci0) by marking its status to "okay".
2. Enabled the LPC snoop engine, configuring snoop ports at 0x80 and
   0x81.

These changes are required to support PECI communication and LPC
snooping for system monitoring and debugging purposes.

To: Ninad Palsule <ninad@linux.ibm.com>
To: Joel Stanley <joel@jms.id.au>
To: Andrew Jeffery <andrew@codeconstruct.com.au>
To: openbmc@lists.ozlabs.org
To: Eddie James <eajames@linux.ibm.com>
To: Rob Herring <robh+dt@kernel.org>
To: Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-aspeed@lists.ozlabs.org
Cc: linux-kernel@vger.kernel.org

Changes in v2:
- Added ibm system1 in the subject & added upstream mailing
  list as well for reviews.
- Link to v1: https://lore.kernel.org/r/20240917-dts-aspeed-system1-peci-snoop-v1-1-b967fb3a6735@gmail.com
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts
index cb3063413d1f..738a86c787c0 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts
@@ -464,6 +464,15 @@ &kcs3 {
 	aspeed,lpc-interrupts = <11 IRQ_TYPE_LEVEL_LOW>;
 };
 
+&peci0 {
+	status = "okay";
+};
+
+&lpc_snoop {
+	status = "okay";
+	snoop-ports = <0x80>, <0x81>;
+};
+
 &i2c0 {
 	status = "okay";
 

---
base-commit: ca2478a7d974f38d29d27acb42a952c7f168916e
change-id: 20240917-dts-aspeed-system1-peci-snoop-725c70f4a485

Best regards,
-- 
Manojkiran Eda <manojkiran.eda@gmail.com>

