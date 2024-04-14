From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sun, 14 Apr 2024 20:01:22 +0300
Subject: [PATCH 2/4] ARM: dts: BCM5301X: provide address for SoC MACs on
 ASUS RT-AC3100 & AC88U
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240414-for-soc-asus-rt-ac3100-improvements-v1-2-0e40caf1a70a@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713114081; l=1804;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=XNg5zKIjWsrnhPZDAMtpMUnqzsLMxQHh+/+ZQ+585t0=;
 b=t/VSblLuxfZr5QPDbh12w/4Vklfc40j5/zpD3kJ1fsn+1Jgy484Hj8fpm8pBiKsbzlIBypdCw
 BDYle8UdVEBCdtN8aG+xdGv8ANr9uAecAZMsl9vGAeIG1oJGDx4VrAJ
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Do not leave the providing of a MAC address for an SoC MAC to a driver.
Describe it on the bindings. Provide a distinct MAC address for each SoC
MAC.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dts | 13 ++++++++++++-
 arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts  |  8 +++++++-
 2 files changed, 19 insertions(+), 2 deletions(-)

diff --git a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dts b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dts
index 5f089307cd8c..1655ac95769c 100644
--- a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dts
+++ b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac3100.dts
@@ -13,11 +13,22 @@ / {
 
 	nvram@1c080000 {
 		et0macaddr: et0macaddr {
+			#nvmem-cell-cells = <1>;
 		};
 	};
 };
 
 &gmac0 {
-	nvmem-cells = <&et0macaddr>;
+	nvmem-cells = <&et0macaddr 0>;
+	nvmem-cell-names = "mac-address";
+};
+
+&gmac1 {
+	nvmem-cells = <&et0macaddr 1>;
+	nvmem-cell-names = "mac-address";
+};
+
+&gmac2 {
+	nvmem-cells = <&et0macaddr 2>;
 	nvmem-cell-names = "mac-address";
 };
diff --git a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts
index fd344b55087e..c78f0c7b137d 100644
--- a/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts
+++ b/arch/arm/boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts
@@ -13,6 +13,7 @@ / {
 
 	nvram@1c080000 {
 		et1macaddr: et1macaddr {
+			#nvmem-cell-cells = <1>;
 		};
 	};
 
@@ -117,6 +118,11 @@ &gmac0 {
 };
 
 &gmac1 {
-	nvmem-cells = <&et1macaddr>;
+	nvmem-cells = <&et1macaddr 0>;
+	nvmem-cell-names = "mac-address";
+};
+
+&gmac2 {
+	nvmem-cells = <&et1macaddr 1>;
 	nvmem-cell-names = "mac-address";
 };

-- 
2.40.1

