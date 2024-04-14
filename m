From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 14 Apr 2024 20:01:24 +0300
Subject: [PATCH 4/4] ARM: dts: BCM5301X: remove earlycon on ASUS RT-AC3100
 and ASUS RT-AC88U
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240414-for-soc-asus-rt-ac3100-improvements-v1-4-0e40caf1a70a@arinc9.com>
References: <20240414-for-soc-asus-rt-ac3100-improvements-v1-0-0e40caf1a70a@arinc9.com>
In-Reply-To: <20240414-for-soc-asus-rt-ac3100-improvements-v1-0-0e40caf1a70a@arinc9.com>
To: Florian Fainelli <florian.fainelli@broadcom.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, 
 =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713114081; l=782;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=bi+4TJMCgd5mWbrKWAfCvlVW6KiexBBfcJK3dSc81ko=;
 b=GTKiQLdAfsoaTgGBusvq1BOGZYVRgaLQz3N7CUuH4ORpJJK5s1CxVllSQTlQP2ITzw95wiZwT
 ZdXZ+FP8nnWD6wEUK4XPgCU+AWnIJ2h5k8fdFrMHIqX7InHLHKniYpX
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the earlycon boot argument. As Krzysztof pointed out, earlycon is
for debugging, not regular mainline usage.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
index 84d583168d81..9c7efb1c44f1 100644
--- a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
+++ b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi
@@ -9,10 +9,6 @@
 #include <dt-bindings/leds/common.h>
 
 / {
-	chosen {
-		bootargs = "earlycon";
-	};
-
 	memory@0 {
 		device_type = "memory";
 		reg = <0x00000000 0x08000000>,

-- 
2.40.1

