From: Manojkiran Eda <manojkiran.eda@gmail.com>
Date: Tue, 03 Dec 2024 18:52:45 +0530
Subject: [PATCH] ARM: dts: aspeed: Enable video engine for IBM System1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241203-dts-system1-video-v1-1-008e5e660106@gmail.com>
X-B4-Tracking: v=1; b=H4sIACQGT2cC/x3MMQqAMAxA0atIZgNNtSJeRRzERs1glUZEKd7d4
 viG/xMoR2GFrkgQ+RKVPWRQWcC0jmFhFJ8N1tiarKnQn4r66Mkb4SWedzSmJe/cSK5hyN0ReZb
 7f/bD+36t1tcFYwAAAA==
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>, 
 Eddie James <eajames@linux.ibm.com>, Ninad Palsule <ninad@linux.ibm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 openbmc@lists.ozlabs.org, Manojkiran Eda <manojkiran.eda@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733232165; l=1038;
 i=manojkiran.eda@gmail.com; s=20241203; h=from:subject:message-id;
 bh=ejXpM+ALtz0H3f+cLC7p2P7soAQAZRSfhVgLG/KNusk=;
 b=JjpeBLox0ewhPlPyR7prwy4gXMJDMjI5b0bU4tGW8YA3C9sw1giJi/yDs/0TpN8fL4ElkieUV
 1aQ6F65esdRAp5zDtx9n76PrAZNP1uwmNdM+yruTohVCsvcdrDKlH7S
X-Developer-Key: i=manojkiran.eda@gmail.com; a=ed25519;
 pk=54WqHEFtBzlAODOpTWKI2J1uhv/sAk3WQ+lDMxMyKTI=
X-Endpoint-Received: by B4 Relay for manojkiran.eda@gmail.com/20241203 with auth_id=292
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Manojkiran Eda <manojkiran.eda@gmail.com>
---
This patch enables the aspeed video engine support in ASPEED BMC for
IBM System1. It is crucial for facilitating the BMC's video capture
and redirection capabilities, which are integral to remote management
and KVM (Keyboard-Video-Mouse) over IP functionality.
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts
index c8597dcded31..bea858b2eee6 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-ibm-system1.dts
@@ -479,6 +479,10 @@ &lpc_snoop {
 	snoop-ports = <0x80>, <0x81>;
 };
 
+&video {
+	status = "okay";
+};
+
 &i2c0 {
 	status = "okay";
 

---
base-commit: f6d73b12ca9fd3b1c29a6a725cd751b972c740cf
change-id: 20241203-dts-system1-video-0081d55a156e

Best regards,
-- 
Manojkiran Eda <manojkiran.eda@gmail.com>

