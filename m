From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 18 Feb 2024 20:02:52 +0800
Subject: [PATCH v2 3/3] arm64: dts: hi3798cv200: add cache info
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240218-cache-v2-3-1fd919e2bd3e@outlook.com>
References: <20240218-cache-v2-0-1fd919e2bd3e@outlook.com>
In-Reply-To: <20240218-cache-v2-0-1fd919e2bd3e@outlook.com>
To: Wei Xu <xuwei5@hisilicon.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, Alex Elder <elder@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708257770; l=2811;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=JVX6c8jTFahxkecrZwVOU639nIRHmAeZFLG8nHeqRQM=;
 b=JfVOap8CG+9J+E/Wm9alsBTwAWzwAa30YeKl9pEufes8+h0zju2JexaoXi9zJ24xOTA6Ym/tx
 3BKeMaXqBtQA/Lc5JcMCrWHU37OQ1tA6/S3j7lG/WBT03JlR3QilC2D
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During boot, the kernel complains:

[    0.044029] cacheinfo: Unable to detect cache hierarchy for CPU 0

So add L1/L2 cache info to the dts according to the datasheet. (32KiB L1
i-cache + 32 KiB L1 d-cache + 512 KiB L2 unified cache)

With this patch, the line above is gone and the following info is added
to the output of `lscpu`:

Caches (sum of all):
  L1d:                   128 KiB (4 instances)
  L1i:                   128 KiB (4 instances)
  L2:                    512 KiB (1 instance)

Fixes: 2f20182ed670 ("arm64: dts: hisilicon: add dts files for hi3798cv200-poplar board")
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi | 37 ++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
index fc64d2fa99eb..0a9533786f50 100644
--- a/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
+++ b/arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi
@@ -31,6 +31,13 @@ cpu@0 {
 			device_type = "cpu";
 			reg = <0x0 0x0>;
 			enable-method = "psci";
+			d-cache-size = <0x8000>; /* 32 KiB */
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			i-cache-size = <0x8000>; /* 32 KiB */
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			next-level-cache = <&L2_0>;
 		};
 
 		cpu@1 {
@@ -38,6 +45,13 @@ cpu@1 {
 			device_type = "cpu";
 			reg = <0x0 0x1>;
 			enable-method = "psci";
+			d-cache-size = <0x8000>; /* 32 KiB */
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			i-cache-size = <0x8000>; /* 32 KiB */
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			next-level-cache = <&L2_0>;
 		};
 
 		cpu@2 {
@@ -45,6 +59,13 @@ cpu@2 {
 			device_type = "cpu";
 			reg = <0x0 0x2>;
 			enable-method = "psci";
+			d-cache-size = <0x8000>; /* 32 KiB */
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			i-cache-size = <0x8000>; /* 32 KiB */
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			next-level-cache = <&L2_0>;
 		};
 
 		cpu@3 {
@@ -52,9 +73,25 @@ cpu@3 {
 			device_type = "cpu";
 			reg = <0x0 0x3>;
 			enable-method = "psci";
+			d-cache-size = <0x8000>; /* 32 KiB */
+			d-cache-line-size = <64>;
+			d-cache-sets = <128>;
+			i-cache-size = <0x8000>; /* 32 KiB */
+			i-cache-line-size = <64>;
+			i-cache-sets = <256>;
+			next-level-cache = <&L2_0>;
 		};
 	};
 
+	L2_0: l2-cache0 {
+		compatible = "cache";
+		cache-unified;
+		cache-size = <0x80000>; /* 512 KiB */
+		cache-line-size = <64>;
+		cache-sets = <512>;
+		cache-level = <2>;
+	};
+
 	gic: interrupt-controller@f1001000 {
 		compatible = "arm,gic-400";
 		reg = <0x0 0xf1001000 0x0 0x1000>,  /* GICD */

-- 
2.43.0

