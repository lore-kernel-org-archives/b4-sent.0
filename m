From: "Chester A. Unal" <chester.a.unal@arinc9.com>
Date: Mon, 03 Mar 2025 13:06:50 +0000
Subject: [PATCH] ARM: dts: BCM5301X: Fix switch port labels of ASUS
 RT-AC5300
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250303-for-broadcom-fix-rt-ac5300-switch-ports-v1-1-e058856ef4d3@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAGmpxWcC/x2NQQqDMBAAvyJ77sI20Yb2K6WHmKx1DzWyG2xB/
 HuDx4FhZgdjFTZ4dDsob2JSlgbXSwdpjsubUXJjcOQG8uRxKoqjlphT+eAkP9SKMQ2eCO0rNc2
 4Fq2GIdzGQD1nF+7Qaqtys8/T83Ucf/OpD9N5AAAA
X-Change-ID: 20250303-for-broadcom-fix-rt-ac5300-switch-ports-776b704ed279
To: Florian Fainelli <florian.fainelli@broadcom.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, 
 =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Tom Brautaset <tbrautaset@gmail.com>, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 Linus Walleij <linus.walleij@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, "Chester A. Unal" <chester.a.unal@arinc9.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741007221; l=1355;
 i=chester.a.unal@arinc9.com; s=arinc9; h=from:subject:message-id;
 bh=pnEACfUXw4i/i7KomdhkZyj3vwZ11bi8No1VYOFnwDs=;
 b=qLc0CTqWEMG6zp53x9qNafll5DaO+iOLlCT86V716Yc1ca2n5cHbE8Kbt6Cg9WBKQgh9SCUWJ
 F5fOYwVex56C5CTxFBl9oDM/M4keZbY0lv0dqahvCYqSn3bKx9yQyqv
X-Developer-Key: i=chester.a.unal@arinc9.com; a=ed25519;
 pk=/g3vBAV0YSvcIpSQ052xJbid7nrPXz8ExGKhTEuc6IY=
X-Endpoint-Received: by B4 Relay for chester.a.unal@arinc9.com/arinc9 with auth_id=306
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After using the device for a while, Tom reports that he initially described
the switch port labels incorrectly. Correct them.

Reported-by: Tom Brautaset <tbrautaset@gmail.com>
Fixes: 961dedc6b4e4 ("ARM: dts: BCM5301X: Add DT for ASUS RT-AC5300")
Signed-off-by: Chester A. Unal <chester.a.unal@arinc9.com>
---
 arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts
index 6c666dc7ad23ef7c31ac22904c39789838caea2e..01ec8c03686a66dd1efa439333f83737fe572191 100644
--- a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts
+++ b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts
@@ -126,11 +126,11 @@ &srab {
 
 	ports {
 		port@0 {
-			label = "lan4";
+			label = "wan";
 		};
 
 		port@1 {
-			label = "lan3";
+			label = "lan1";
 		};
 
 		port@2 {
@@ -138,11 +138,11 @@ port@2 {
 		};
 
 		port@3 {
-			label = "lan1";
+			label = "lan3";
 		};
 
 		port@4 {
-			label = "wan";
+			label = "lan4";
 		};
 	};
 };

---
base-commit: 768953614c1c13fdf771be5742f1be573eea8fa4
change-id: 20250303-for-broadcom-fix-rt-ac5300-switch-ports-776b704ed279

Best regards,
-- 
Chester A. Unal <chester.a.unal@arinc9.com>

