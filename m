From: "Chester A. Unal" <chester.a.unal@arinc9.com>
Date: Tue, 04 Mar 2025 15:55:36 +0000
Subject: [PATCH] ARM: dts: BCM5301X: Fix switch port labels of ASUS
 RT-AC3200
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-for-broadcom-fix-rt-ac3200-switch-ports-v1-1-7e249a19a13e@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAHcix2cC/x2NywrCMBAAf6Xs2YVt0oL6K+Ihj43dg92yCVUo/
 XeDx4Fh5oDKJlzhPhxgvEsVXTuMlwHSEtYXo+TO4MjN5GnCoobRNOSkbyzyRWsYkndEWD/S0oK
 bWquYuYwUyMd4vUGvbcbd/p8ez/P8AQpCTjx5AAAA
X-Change-ID: 20250304-for-broadcom-fix-rt-ac3200-switch-ports-def10a03bb89
To: Florian Fainelli <florian.fainelli@broadcom.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, 
 =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Tom Brautaset <tbrautaset@gmail.com>, 
 "Chester A. Unal" <chester.a.unal@arinc9.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741103743; l=1391;
 i=chester.a.unal@arinc9.com; s=arinc9; h=from:subject:message-id;
 bh=5BwPF9flLou8o24Bv8iNZhdALbMlAOZ+jVIvmAjgycU=;
 b=PeGf3b5jyl/AR9FiXgqhGgQx7n+rYzrkdnnzZfnJJjgmQXZMpnSVYUJsyWjdEeBXq8Hup0E0s
 siibCPmaodZANVCthjQnH02OQqMLTxYWmU0G2MU8BQrx0p5iwFE/CRz
X-Developer-Key: i=chester.a.unal@arinc9.com; a=ed25519;
 pk=/g3vBAV0YSvcIpSQ052xJbid7nrPXz8ExGKhTEuc6IY=
X-Endpoint-Received: by B4 Relay for chester.a.unal@arinc9.com/arinc9 with auth_id=306
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After using the device for a while, Tom reports that he initially described
the switch port labels incorrectly. Apparently, ASUS's own firmware also
describes them incorrectly. Correct them to what is seen on the chassis.

Reported-by: Tom Brautaset <tbrautaset@gmail.com>
Fixes: b116239094d8 ("ARM: dts: BCM5301X: Add DT for ASUS RT-AC3200")
Signed-off-by: Chester A. Unal <chester.a.unal@arinc9.com>
---
 arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts b/arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts
index 53cb0c58f6d0574f4f13c6aeb1d1bc5961d80379..3da2daee0c849d536df94c868849af7610cc1ded 100644
--- a/arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts
+++ b/arch/arm/boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts
@@ -124,19 +124,19 @@ port@0 {
 		};
 
 		port@1 {
-			label = "lan1";
+			label = "lan4";
 		};
 
 		port@2 {
-			label = "lan2";
+			label = "lan3";
 		};
 
 		port@3 {
-			label = "lan3";
+			label = "lan2";
 		};
 
 		port@4 {
-			label = "lan4";
+			label = "lan1";
 		};
 	};
 };

---
base-commit: 768953614c1c13fdf771be5742f1be573eea8fa4
change-id: 20250304-for-broadcom-fix-rt-ac3200-switch-ports-def10a03bb89

Best regards,
-- 
Chester A. Unal <chester.a.unal@arinc9.com>

