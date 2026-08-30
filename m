From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 16:22:08 +0200
Subject: [PATCH 2/3] arm64: dts: apple: t6030: Fix cpus node indentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-dts-fixes-v1-2-cc20f8445754@kernel.org>
References: <20260830-b4-apple-dts-fixes-v1-0-cc20f8445754@kernel.org>
In-Reply-To: <20260830-b4-apple-dts-fixes-v1-0-cc20f8445754@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=702; i=sven@kernel.org;
 h=from:subject:message-id; bh=DzWRAVjSbOt2fmkIlgKACC5xJIcKFQRvLBJixPdk5hA=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9YUm3mTvpemPl/lYX/B4sD0ctmWj1UnfNU/z3FjDrUyk
 PNaXlXYUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjIL1eGf+bdlj3PejY7LXt9
 atFhZUbblW+Wygpe+OAuobx/w+e5C5oZfjJemva5XKrzybOHq8o2TCg7XvvvXoWGwpRpbo3+281
 P7uMAAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop the extra space indentation of the closing brace of the cpus node.

Fixes: e81af013dbdd ("arm64: dts: apple: Initial T6030 (M3 Pro) device trees")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t6030.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/apple/t6030.dtsi b/arch/arm64/boot/dts/apple/t6030.dtsi
index dda9568af11f..5ff12edfc553 100644
--- a/arch/arm64/boot/dts/apple/t6030.dtsi
+++ b/arch/arm64/boot/dts/apple/t6030.dtsi
@@ -208,7 +208,7 @@ l2_cache_1: l2-cache-1 {
 			cache-unified;
 			cache-size = <0x1000000>;
 		};
-	 };
+	};
 
 	timer {
 		compatible = "arm,armv8-timer";

-- 
2.55.0

