From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 16:22:09 +0200
Subject: [PATCH 3/3] arm64: dts: apple: t6032: Fix cpus node indentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-dts-fixes-v1-3-cc20f8445754@kernel.org>
References: <20260830-b4-apple-dts-fixes-v1-0-cc20f8445754@kernel.org>
In-Reply-To: <20260830-b4-apple-dts-fixes-v1-0-cc20f8445754@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=725; i=sven@kernel.org;
 h=from:subject:message-id; bh=BZZYf9REXU7acvmjIiBUNWktgp5lIoBvVJa7kgwRxaY=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9YUm/kbbz1N+Xc39Nhxa/8db+VatcWXH+ep6lVWXHDUJ
 b807v2jjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBE+EMYGS4EqpoEG/mtiji0
 N5h3iayH06Vom2ku/e/OGBkvfXEiP4/hf36xJZeTEpPt80+72K5fEj00oWnuaYWiiEYhrQXBTf1
 fmAE=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drop the extra space indentation of the closing brace of the cpus node.

Fixes: 67d9574cf8ed ("arm64: dts: apple: Initial T603[124] (M3 Max and Ultra) device trees")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t6032.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/apple/t6032.dtsi b/arch/arm64/boot/dts/apple/t6032.dtsi
index bbf19ecdaaec..61d044f3a734 100644
--- a/arch/arm64/boot/dts/apple/t6032.dtsi
+++ b/arch/arm64/boot/dts/apple/t6032.dtsi
@@ -283,7 +283,7 @@ l2_cache_5: l2-cache-5 {
 			cache-unified;
 			cache-size = <0x1000000>;
 		};
-	 };
+	};
 
 	die0: soc@200000000 {
 		compatible = "simple-bus";

-- 
2.55.0

