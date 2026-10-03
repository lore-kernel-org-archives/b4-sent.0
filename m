From: Sven Peter <sven@kernel.org>
Date: Sat, 03 Oct 2026 22:51:02 +0200
Subject: [PATCH v3 3/3] arm64: dts: apple: Add CIO reset controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-b4-cio-reset-v3-3-e605f9e5c8a4@kernel.org>
References: <20261003-b4-cio-reset-v3-0-e605f9e5c8a4@kernel.org>
In-Reply-To: <20261003-b4-cio-reset-v3-0-e605f9e5c8a4@kernel.org>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: Joshua Peisach <jpeisach@ubuntu.com>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3435; i=sven@kernel.org;
 h=from:subject:message-id; bh=O9/xTiB/nsj+z0f4cAFHK8h8/BCndTASTlct8vI9OM4=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bBrF3e36Xf65l2ygawfC77Hst9J+Cg45HnndzdByuPb
 Zcodf/UUcrCIMbFICumyLJ9v73pk4dvBJduuvQeZg4rE8gQBi5OAZjIrwmMDO9q3N+IaMxK0w89
 8lKvf2acaNHuR7JHBGtEEq4Vc3cUv2VkuHGsv/3MWnWz40c1eWdYPF2qcmim1Ww285m/o7MCz2y
 XZwAA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the reset controllers used to start the CIO (USB4/Thunderbolt)
blocks on t8103 and t600x. On t8103 each port comes with a dedicated
register page represented as a standalone node. On t600x a single
register shared by all ports of a die is located in the middle of the
PMGR MMIO region and represented as a sub-node of its syscon.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi | 8 +++++++-
 arch/arm64/boot/dts/apple/t602x-dieX.dtsi | 8 +++++++-
 arch/arm64/boot/dts/apple/t8103.dtsi      | 6 ++++++
 arch/arm64/boot/dts/apple/t8112.dtsi      | 6 ++++++
 4 files changed, 26 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
index 9676d5127039..5e163d756a7f 100644
--- a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
@@ -28,7 +28,13 @@ DIE_NODE(pmgr): power-management@28e080000 {
 		compatible = "apple,t6000-pmgr", "apple,pmgr", "syscon", "simple-mfd";
 		#address-cells = <1>;
 		#size-cells = <1>;
-		reg = <0x2 0x8e080000 0 0x4000>;
+		reg = <0x2 0x8e080000 0 0x1c000>;
+
+		DIE_NODE(cio_reset): reset-controller@1a034 {
+			compatible = "apple,t6000-cio-reset";
+			reg = <0x1a034 0x4>;
+			#reset-cells = <1>;
+		};
 	};
 
 	DIE_NODE(pmgr_east): power-management@28e580000 {
diff --git a/arch/arm64/boot/dts/apple/t602x-dieX.dtsi b/arch/arm64/boot/dts/apple/t602x-dieX.dtsi
index ae3d535c5acb..fd4d572a04e7 100644
--- a/arch/arm64/boot/dts/apple/t602x-dieX.dtsi
+++ b/arch/arm64/boot/dts/apple/t602x-dieX.dtsi
@@ -27,7 +27,13 @@ DIE_NODE(pmgr): power-management@28e080000 {
 		compatible = "apple,t6020-pmgr", "apple,t8103-pmgr", "syscon", "simple-mfd";
 		#address-cells = <1>;
 		#size-cells = <1>;
-		reg = <0x2 0x8e080000 0 0x8000>;
+		reg = <0x2 0x8e080000 0 0xc000>;
+
+		DIE_NODE(cio_reset): reset-controller@a02c {
+			compatible = "apple,t6020-cio-reset", "apple,t6000-cio-reset";
+			reg = <0xa02c 0x4>;
+			#reset-cells = <1>;
+		};
 	};
 
 	DIE_NODE(pmgr_south): power-management@28e680000 {
diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 5b68bf0df4e6..985dbd8e68ca 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -730,6 +730,12 @@ pmgr: power-management@23b700000 {
 			reg = <0x2 0x3b700000 0 0x14000>;
 		};
 
+		cio_reset: reset-controller@23b784000 {
+			compatible = "apple,t8103-cio-reset";
+			reg = <0x2 0x3b784000 0x0 0x8000>;
+			#reset-cells = <1>;
+		};
+
 		pinctrl_ap: pinctrl@23c100000 {
 			compatible = "apple,t8103-pinctrl", "apple,pinctrl";
 			reg = <0x2 0x3c100000 0x0 0x100000>;
diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index ec248ca052cb..2c3b59e05e01 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -737,6 +737,12 @@ pmgr: power-management@23b700000 {
 			/* child nodes are added in t8103-pmgr.dtsi */
 		};
 
+		cio_reset: reset-controller@23b790000 {
+			compatible = "apple,t8112-cio-reset", "apple,t8103-cio-reset";
+			reg = <0x2 0x3b790000 0x0 0x8000>;
+			#reset-cells = <1>;
+		};
+
 		pinctrl_ap: pinctrl@23c100000 {
 			compatible = "apple,t8112-pinctrl", "apple,pinctrl";
 			reg = <0x2 0x3c100000 0x0 0x100000>;

-- 
2.55.0

