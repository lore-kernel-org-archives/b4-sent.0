From: Manojkiran Eda <manojkiran.eda@gmail.com>
Date: Tue, 17 Sep 2024 17:27:08 +0530
Subject: [PATCH] arm: dts: aspeed: Enable PECI and LPC Snoop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240917-dts-aspeed-system1-peci-snoop-v1-1-b967fb3a6735@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJNu6WYC/x3MQQrDIBAF0KuEWXdAxWDbq5QuRH+SWVTFCaUl5
 O6VLt/mHaToAqX7dFDHW1RqGbCXidIWywqWPEzOOG9uNnDelaM2ILN+dcfLckMS1lJr4+DmFMz
 io7/ONI7Wscjn/z+e5/kDtxZUKG8AAAA=
To: Ninad Palsule <ninad@linux.ibm.com>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>, openbmc@lists.ozlabs.org, 
 Eddie James <eajames@linux.ibm.com>
Cc: Manojkiran Eda <manojkiran.eda@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726574241; l=1427;
 i=manojkiran.eda@gmail.com; s=20240917; h=from:subject:message-id;
 bh=/1nUIqnNZDWK/Gq0s2SEC3Nt9jxEcTyK93Dbo2tVeno=;
 b=Mr1/kTJU6zcF2l+GCyb8NtyXvLOg64fP2VpzhFv8/8qfP+p8kmJzx3PlpqZFTkVzCFzoMEvSr
 rYczmGitysQBXvsFFm29c0naO0q+2OgLnEt2TiyVCKVLE3Yv2xoNiD/
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

