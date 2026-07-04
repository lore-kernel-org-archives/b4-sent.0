From: Roman Vivchar <rva333@protonmail.com>
Date: Sat, 04 Jul 2026 22:21:43 +0300
Subject: [PATCH 2/2] ARM: dts: mediatek: mt6572: add cache data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260704-6572-phase1-v1-2-61c2fe6be19c@protonmail.com>
References: <20260704-6572-phase1-v1-0-61c2fe6be19c@protonmail.com>
In-Reply-To: <20260704-6572-phase1-v1-0-61c2fe6be19c@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783192904; l=1386;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=SDakxdcc7QkbCtbafL/keArn3jI3hsMDqsWxhluf3lA=;
 b=D6OZSx1nW4RarZ2Josaqo2/lJX3OtNQVawPvXYZ6zqjyvMR9rd8EDHavRzVnU8ZJGSlS5jPk8
 qV0iizoUJQRDBHuwp3dg0lIrPrwJg3+6W0GS5SHerkv6m32DIAxNnSI
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MediaTek mt6572 includes 32 KB I-cache and D-cache, and 256 KB L2 cache.

Add information about cache size, cache line size and cache sets to the
devicetree.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6572.dtsi | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/mt6572.dtsi b/arch/arm/boot/dts/mediatek/mt6572.dtsi
index fa0e5df766c2..5716505dc9e4 100644
--- a/arch/arm/boot/dts/mediatek/mt6572.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6572.dtsi
@@ -20,11 +20,34 @@ cpu@0 {
 			device_type = "cpu";
 			compatible = "arm,cortex-a7";
 			reg = <0x0>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2>;
 		};
 		cpu@1 {
 			device_type = "cpu";
 			compatible = "arm,cortex-a7";
 			reg = <0x1>;
+			i-cache-size = <32768>;
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			d-cache-size = <32768>;
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			next-level-cache = <&l2>;
+		};
+
+		l2: l2-cache {
+			compatible = "cache";
+			cache-level = <2>;
+			cache-size = <262144>;
+			cache-line-size = <64>;
+			cache-sets = <512>;
+			cache-unified;
 		};
 	};
 

-- 
2.54.0

