From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 16:22:07 +0200
Subject: [PATCH 1/3] arm64: dts: apple: t602x: Fix cpus node indentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-dts-fixes-v1-1-cc20f8445754@kernel.org>
References: <20260830-b4-apple-dts-fixes-v1-0-cc20f8445754@kernel.org>
In-Reply-To: <20260830-b4-apple-dts-fixes-v1-0-cc20f8445754@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=756; i=sven@kernel.org;
 h=from:subject:message-id; bh=XZr0dTCOqATFprJYOJpR1NmA5rDqYT2PR4Gt5cOZ5Qw=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9YUm7kmNy8dzdjSoX58y4TUN1HtkV++B7ua55Q8OKSjG
 KzNyqbYUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjI6xJGhhezXC/K8afdsWvi
 OeZz/Hc+s3finpPHnm1YK/ouktWg8hrD/9Ifmww4VJ7cOnPqtJnOdQe9iW1rP/985nz1zN2XPYr
 ScWwA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop the extra space indentation of the closing brace of the cpus node.

Fixes: e1514f9b3755 ("arm64: dts: apple: Add initial t602x device trees")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t602x-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/apple/t602x-common.dtsi b/arch/arm64/boot/dts/apple/t602x-common.dtsi
index 9c800a391e7e..66b6f8347d19 100644
--- a/arch/arm64/boot/dts/apple/t602x-common.dtsi
+++ b/arch/arm64/boot/dts/apple/t602x-common.dtsi
@@ -254,7 +254,7 @@ l2_cache_2: l2-cache-2 {
 			cache-unified;
 			cache-size = <0x1000000>;
 		};
-	 };
+	};
 
 	blizzard_opp: opp-table-0 {
 		compatible = "operating-points-v2";

-- 
2.55.0

