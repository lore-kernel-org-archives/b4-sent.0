From: Sven Peter <sven@kernel.org>
Date: Sat, 14 Nov 2026 16:26:29 +0100
Subject: [PATCH] arm64: dts: apple: Fix property-order dt-check-style
 warnings for PMGR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-pmgr-dt-fixes-v1-1-97043a460e59@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM3QpAQBCG4VvRHJuyWMqtyAG7g1F+2llScu8Wh
 09f73eBkGMSqKILHB0svC4BKo7AjO0yELINhjRJC6VUjts8OLQeez5JsLRa56XNjNYEodkcfUN
 I6ua37N1Exr8ncN8P+5aq+HEAAAA=
X-Change-ID: 20261114-pmgr-dt-fixes-7d5547d3c55e
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=49977; i=sven@kernel.org;
 h=from:subject:message-id; bh=Nm1FchJVtDZeEGP7A7eV5EIAhYigng235CiguVfJ+WA=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aP2mUvXhycKZ96L/dw/vz50490ec/MXai3ziNYb30Vm
 4Pa09mTOkpZGMS4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATUbnFyPBUv1S1lMnp/6l7
 8bbTOTpmtez6zH6Gc8bXeDaBVa27uPwZGd6bVV36w5LztCD25zSnFRZv2C7nRJYtMmkU/7n0/pS
 r97kA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following dt-check-style warnings by moving apple,always-on
to the end:

  arch/arm64/boot/dts/apple/t600x-pmgr.dtsi:238: [property-order] property 'power-domains' out of canonical order (should sort before 'apple,always-on')

Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t600x-pmgr.dtsi |  46 ++++-----
 arch/arm64/boot/dts/apple/t602x-pmgr.dtsi |  74 +++++++-------
 arch/arm64/boot/dts/apple/t6030-pmgr.dtsi |  20 ++--
 arch/arm64/boot/dts/apple/t6031-pmgr.dtsi | 156 +++++++++++++++---------------
 arch/arm64/boot/dts/apple/t8103-pmgr.dtsi |   4 +-
 arch/arm64/boot/dts/apple/t8112-pmgr.dtsi |   2 +-
 6 files changed, 151 insertions(+), 151 deletions(-)

diff --git a/arch/arm64/boot/dts/apple/t600x-pmgr.dtsi b/arch/arm64/boot/dts/apple/t600x-pmgr.dtsi
index 0bd44753b76a..47a381449ac4 100644
--- a/arch/arm64/boot/dts/apple/t600x-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-pmgr.dtsi
@@ -234,8 +234,8 @@ DIE_NODE(ps_afnc1_ioa): power-controller@1f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc0_ioa): power-controller@1f8 {
@@ -244,8 +244,8 @@ DIE_NODE(ps_afnc0_ioa): power-controller@1f8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_ls): power-controller@200 {
@@ -254,8 +254,8 @@ DIE_NODE(ps_afnc1_ls): power-controller@200 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc0_ls): power-controller@208 {
@@ -264,8 +264,8 @@ DIE_NODE(ps_afnc0_ls): power-controller@208 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc0_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_lw0): power-controller@210 {
@@ -274,8 +274,8 @@ DIE_NODE(ps_afnc1_lw0): power-controller@210 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_lw1): power-controller@218 {
@@ -284,8 +284,8 @@ DIE_NODE(ps_afnc1_lw1): power-controller@218 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw1);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_lw2): power-controller@220 {
@@ -294,8 +294,8 @@ DIE_NODE(ps_afnc1_lw2): power-controller@220 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw2);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc0_lw0): power-controller@228 {
@@ -304,8 +304,8 @@ DIE_NODE(ps_afnc0_lw0): power-controller@228 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc0_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_scodec): power-controller@230 {
@@ -745,8 +745,8 @@ DIE_NODE(ps_afnc2_ioa): power-controller@148 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc2_ls): power-controller@150 {
@@ -755,8 +755,8 @@ DIE_NODE(ps_afnc2_ls): power-controller@150 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc2_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc2_lw0): power-controller@158 {
@@ -765,8 +765,8 @@ DIE_NODE(ps_afnc2_lw0): power-controller@158 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc2_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc2_lw1): power-controller@160 {
@@ -775,8 +775,8 @@ DIE_NODE(ps_afnc2_lw1): power-controller@160 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_lw1);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc2_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc3_ioa): power-controller@168 {
@@ -785,8 +785,8 @@ DIE_NODE(ps_afnc3_ioa): power-controller@168 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc3_ls): power-controller@170 {
@@ -795,8 +795,8 @@ DIE_NODE(ps_afnc3_ls): power-controller@170 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc3_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc3_lw0): power-controller@178 {
@@ -805,8 +805,8 @@ DIE_NODE(ps_afnc3_lw0): power-controller@178 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc3_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_sio): power-controller@180 {
@@ -1645,8 +1645,8 @@ DIE_NODE(ps_afnc4_ioa): power-controller@1a0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc4_ls): power-controller@1a8 {
@@ -1655,8 +1655,8 @@ DIE_NODE(ps_afnc4_ls): power-controller@1a8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc4_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc4_lw0): power-controller@1b0 {
@@ -1665,8 +1665,8 @@ DIE_NODE(ps_afnc4_lw0): power-controller@1b0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc4_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc5_ioa): power-controller@1b8 {
@@ -1675,8 +1675,8 @@ DIE_NODE(ps_afnc5_ioa): power-controller@1b8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc5_ls): power-controller@1c0 {
@@ -1685,8 +1685,8 @@ DIE_NODE(ps_afnc5_ls): power-controller@1c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc5_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc5_lw0): power-controller@1c8 {
@@ -1695,8 +1695,8 @@ DIE_NODE(ps_afnc5_lw0): power-controller@1c8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc5_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_dispext2_fe): power-controller@1d0 {
@@ -1960,8 +1960,8 @@ DIE_NODE(ps_debug_usb): power-controller@c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(debug_usb);
-		apple,always-on; /* Core AON device */
 		power-domains = <&DIE_NODE(ps_debug)>;
+		apple,always-on; /* Core AON device */
 	};
 
 	DIE_NODE(ps_debug_auth): power-controller@c8 {
@@ -1970,8 +1970,8 @@ DIE_NODE(ps_debug_auth): power-controller@c8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(debug_auth);
-		apple,always-on; /* Core AON device */
 		power-domains = <&DIE_NODE(ps_debug)>;
+		apple,always-on; /* Core AON device */
 	};
 
 	DIE_NODE(ps_atc0_usb): power-controller@d0 {
diff --git a/arch/arm64/boot/dts/apple/t602x-pmgr.dtsi b/arch/arm64/boot/dts/apple/t602x-pmgr.dtsi
index f5382a2faf0b..3e8233a99293 100644
--- a/arch/arm64/boot/dts/apple/t602x-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t602x-pmgr.dtsi
@@ -173,8 +173,8 @@ DIE_NODE(ps_afnc1_ioa): power-controller@1b8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afc): power-controller@1d0 {
@@ -192,8 +192,8 @@ DIE_NODE(ps_afnc0_ioa): power-controller@1e8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_ls): power-controller@1f0 {
@@ -202,8 +202,8 @@ DIE_NODE(ps_afnc1_ls): power-controller@1f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc0_ls): power-controller@1f8 {
@@ -212,8 +212,8 @@ DIE_NODE(ps_afnc0_ls): power-controller@1f8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc0_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_lw0): power-controller@200 {
@@ -222,8 +222,8 @@ DIE_NODE(ps_afnc1_lw0): power-controller@200 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_lw1): power-controller@208 {
@@ -232,8 +232,8 @@ DIE_NODE(ps_afnc1_lw1): power-controller@208 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw1);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc1_lw2): power-controller@210 {
@@ -242,8 +242,8 @@ DIE_NODE(ps_afnc1_lw2): power-controller@210 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw2);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc0_lw0): power-controller@218 {
@@ -252,8 +252,8 @@ DIE_NODE(ps_afnc0_lw0): power-controller@218 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc0_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_scodec): power-controller@220 {
@@ -316,8 +316,8 @@ DIE_NODE(ps_pms_bridge): power-controller@250 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(pms_bridge);
-		apple,always-on; /* Core device */
 		power-domains = <&DIE_NODE(ps_afnc0_lw0)>;
+		apple,always-on; /* Core device */
 	};
 
 	DIE_NODE(ps_dispext0_sys): power-controller@258 {
@@ -813,8 +813,8 @@ DIE_NODE(ps_afnc4_ioa): power-controller@1a0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc4_ls): power-controller@1a8 {
@@ -823,8 +823,8 @@ DIE_NODE(ps_afnc4_ls): power-controller@1a8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc4_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc4_lw0): power-controller@1b0 {
@@ -833,8 +833,8 @@ DIE_NODE(ps_afnc4_lw0): power-controller@1b0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc4_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc5_ioa): power-controller@1b8 {
@@ -843,8 +843,8 @@ DIE_NODE(ps_afnc5_ioa): power-controller@1b8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_ioa);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc5_ls): power-controller@1c0 {
@@ -853,8 +853,8 @@ DIE_NODE(ps_afnc5_ls): power-controller@1c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_ls);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc5_ioa)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_afnc5_lw0): power-controller@1c8 {
@@ -863,8 +863,8 @@ DIE_NODE(ps_afnc5_lw0): power-controller@1c8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_lw0);
-		apple,always-on; /* Apple Fabric */
 		power-domains = <&DIE_NODE(ps_afnc5_ls)>;
+		apple,always-on; /* Apple Fabric */
 	};
 
 	DIE_NODE(ps_dispext2_sys): power-controller@1d0 {
@@ -1076,8 +1076,8 @@ DIE_NODE(ps_afnc6_ioa): power-controller@148 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc6_ioa);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc6_ls): power-controller@150 {
@@ -1086,8 +1086,8 @@ DIE_NODE(ps_afnc6_ls): power-controller@150 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc6_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc6_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc6_lw0): power-controller@158 {
@@ -1096,8 +1096,8 @@ DIE_NODE(ps_afnc6_lw0): power-controller@158 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc6_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc6_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_ioa): power-controller@160 {
@@ -1106,8 +1106,8 @@ DIE_NODE(ps_afnc2_ioa): power-controller@160 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_ioa);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_dcs_10)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_ls): power-controller@168 {
@@ -1116,8 +1116,8 @@ DIE_NODE(ps_afnc2_ls): power-controller@168 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc2_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_lw0): power-controller@170 {
@@ -1126,8 +1126,8 @@ DIE_NODE(ps_afnc2_lw0): power-controller@170 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc2_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_lw1): power-controller@178 {
@@ -1136,8 +1136,8 @@ DIE_NODE(ps_afnc2_lw1): power-controller@178 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_lw1);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc2_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc3_ioa): power-controller@180 {
@@ -1146,8 +1146,8 @@ DIE_NODE(ps_afnc3_ioa): power-controller@180 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_ioa);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc3_ls): power-controller@188 {
@@ -1156,8 +1156,8 @@ DIE_NODE(ps_afnc3_ls): power-controller@188 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc3_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc3_lw0): power-controller@190 {
@@ -1166,8 +1166,8 @@ DIE_NODE(ps_afnc3_lw0): power-controller@190 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc3_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_apcie_gp): power-controller@198 {
@@ -1439,8 +1439,8 @@ DIE_NODE(ps_aes): power-controller@280 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(aes);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_sio)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dptx_phy_ps): power-controller@288 {
@@ -2070,8 +2070,8 @@ DIE_NODE(ps_mtp_fabric): power-controller@b0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_fabric);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_fabric)>;
+		apple,always-on;
 		status = "disabled";
 	};
 
@@ -2137,8 +2137,8 @@ DIE_NODE(ps_mtp_gpio): power-controller@e8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_gpio);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_base): power-controller@f0 {
@@ -2147,8 +2147,8 @@ DIE_NODE(ps_mtp_base): power-controller@f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_base);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_periph): power-controller@f8 {
@@ -2157,8 +2157,8 @@ DIE_NODE(ps_mtp_periph): power-controller@f8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_periph);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_spi0): power-controller@100 {
@@ -2167,8 +2167,8 @@ DIE_NODE(ps_mtp_spi0): power-controller@100 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_spi0);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_i2cm0): power-controller@108 {
@@ -2177,8 +2177,8 @@ DIE_NODE(ps_mtp_i2cm0): power-controller@108 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_i2cm0);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_uart0): power-controller@110 {
@@ -2187,8 +2187,8 @@ DIE_NODE(ps_mtp_uart0): power-controller@110 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_uart0);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_cpu): power-controller@118 {
@@ -2197,8 +2197,8 @@ DIE_NODE(ps_mtp_cpu): power-controller@118 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_cpu);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_scm_fabric): power-controller@120 {
@@ -2207,8 +2207,8 @@ DIE_NODE(ps_mtp_scm_fabric): power-controller@120 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_scm_fabric);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_periph)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_sram): power-controller@128 {
@@ -2217,8 +2217,8 @@ DIE_NODE(ps_mtp_sram): power-controller@128 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_sram);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_scm_fabric)>, <&DIE_NODE(ps_mtp_cpu)>;
+		apple,always-on; /* MTP always stays on */
 	};
 
 	DIE_NODE(ps_mtp_dma): power-controller@130 {
@@ -2227,8 +2227,8 @@ DIE_NODE(ps_mtp_dma): power-controller@130 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_dma);
-		apple,always-on; /* MTP always stays on */
 		power-domains = <&DIE_NODE(ps_mtp_sram)>;
+		apple,always-on; /* MTP always stays on */
 	};
 #endif
 };
diff --git a/arch/arm64/boot/dts/apple/t6030-pmgr.dtsi b/arch/arm64/boot/dts/apple/t6030-pmgr.dtsi
index b890d622566e..cc281943aa73 100644
--- a/arch/arm64/boot/dts/apple/t6030-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t6030-pmgr.dtsi
@@ -501,8 +501,8 @@ ps_dpa0: power-controller@2e0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "dpa0";
-		apple,always-on;
 		power-domains = <&ps_audio_p>;
+		apple,always-on;
 	};
 
 	ps_dpa1: power-controller@2e8 {
@@ -511,8 +511,8 @@ ps_dpa1: power-controller@2e8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "dpa1";
-		apple,always-on;
 		power-domains = <&ps_audio_p>;
+		apple,always-on;
 	};
 
 	ps_dpa2: power-controller@2f0 {
@@ -521,8 +521,8 @@ ps_dpa2: power-controller@2f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "dpa2";
-		apple,always-on;
 		power-domains = <&ps_audio_p>;
+		apple,always-on;
 	};
 
 	ps_dpa3: power-controller@2f8 {
@@ -531,8 +531,8 @@ ps_dpa3: power-controller@2f8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "dpa3";
-		apple,always-on;
 		power-domains = <&ps_audio_p>;
+		apple,always-on;
 	};
 
 	ps_dpa4: power-controller@300 {
@@ -541,8 +541,8 @@ ps_dpa4: power-controller@300 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "dpa4";
-		apple,always-on;
 		power-domains = <&ps_audio_p>;
+		apple,always-on;
 	};
 
 	ps_mca0: power-controller@308 {
@@ -704,8 +704,8 @@ ps_ls1: power-controller@3a8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "ls1";
-		apple,always-on;
 		power-domains = <&ps_ioa1>;
+		apple,always-on;
 	};
 
 	ps_lw10: power-controller@3b0 {
@@ -714,8 +714,8 @@ ps_lw10: power-controller@3b0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "lw10";
-		apple,always-on;
 		power-domains = <&ps_ls1>;
+		apple,always-on;
 	};
 
 	ps_dispext0_sys: power-controller@3b8 {
@@ -855,8 +855,8 @@ ps_ls3: power-controller@4b8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "ls3";
-		apple,always-on;
 		power-domains = <&ps_ioa3>;
+		apple,always-on;
 	};
 
 	ps_lw30: power-controller@4c0 {
@@ -865,8 +865,8 @@ ps_lw30: power-controller@4c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "lw30";
-		apple,always-on;
 		power-domains = <&ps_ls3>;
+		apple,always-on;
 	};
 
 	ps_pmp: power-controller@4c8 {
@@ -891,8 +891,8 @@ ps_lw31: power-controller@4d8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "lw31";
-		apple,always-on;
 		power-domains = <&ps_ls3>;
+		apple,always-on;
 	};
 
 	ps_atc0_common: power-controller@4e0 {
diff --git a/arch/arm64/boot/dts/apple/t6031-pmgr.dtsi b/arch/arm64/boot/dts/apple/t6031-pmgr.dtsi
index 721ab2e9fd4b..578d267888b0 100644
--- a/arch/arm64/boot/dts/apple/t6031-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t6031-pmgr.dtsi
@@ -53,8 +53,8 @@ DIE_NODE(ps_afnc3_ls): power-controller@128 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc3_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc3_lw0): power-controller@138 {
@@ -63,8 +63,8 @@ DIE_NODE(ps_afnc3_lw0): power-controller@138 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc3_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc3_lw1): power-controller@148 {
@@ -73,8 +73,8 @@ DIE_NODE(ps_afnc3_lw1): power-controller@148 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc3_lw1);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc3_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_apcie_sys_gp): power-controller@158 {
@@ -101,8 +101,8 @@ DIE_NODE(ps_afnc4_ls): power-controller@178 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc4_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc4_lw0): power-controller@188 {
@@ -111,8 +111,8 @@ DIE_NODE(ps_afnc4_lw0): power-controller@188 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc4_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc4_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc5_ioa): power-controller@198 {
@@ -130,8 +130,8 @@ DIE_NODE(ps_afnc5_ls): power-controller@1a8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc5_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc5_lw0): power-controller@1b8 {
@@ -140,8 +140,8 @@ DIE_NODE(ps_afnc5_lw0): power-controller@1b8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc5_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc5_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc6_ioa): power-controller@1c8 {
@@ -159,8 +159,8 @@ DIE_NODE(ps_afnc6_ls): power-controller@1d8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc6_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc6_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc6_lw0): power-controller@1e8 {
@@ -169,8 +169,8 @@ DIE_NODE(ps_afnc6_lw0): power-controller@1e8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc6_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc6_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_sio): power-controller@1f8 {
@@ -350,8 +350,8 @@ DIE_NODE(ps_aes): power-controller@290 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(aes);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_sio)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_disp_fe): power-controller@298 {
@@ -604,8 +604,8 @@ DIE_NODE(ps_dcs_04): power-controller@390 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_04);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc1)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_05): power-controller@3a0 {
@@ -614,8 +614,8 @@ DIE_NODE(ps_dcs_05): power-controller@3a0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_05);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc1)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_06): power-controller@3b0 {
@@ -624,8 +624,8 @@ DIE_NODE(ps_dcs_06): power-controller@3b0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_06);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc1)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_07): power-controller@3c0 {
@@ -634,8 +634,8 @@ DIE_NODE(ps_dcs_07): power-controller@3c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_07);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc1)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_12): power-controller@3d0 {
@@ -644,8 +644,8 @@ DIE_NODE(ps_dcs_12): power-controller@3d0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_12);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc3)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_13): power-controller@3e0 {
@@ -654,8 +654,8 @@ DIE_NODE(ps_dcs_13): power-controller@3e0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_13);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc3)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_14): power-controller@3f0 {
@@ -664,8 +664,8 @@ DIE_NODE(ps_dcs_14): power-controller@3f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_14);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc3)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_15): power-controller@400 {
@@ -674,8 +674,8 @@ DIE_NODE(ps_dcs_15): power-controller@400 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_15);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc3)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_20): power-controller@410 {
@@ -684,8 +684,8 @@ DIE_NODE(ps_dcs_20): power-controller@410 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_20);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc5)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_21): power-controller@420 {
@@ -694,8 +694,8 @@ DIE_NODE(ps_dcs_21): power-controller@420 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_21);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc5)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_22): power-controller@430 {
@@ -704,8 +704,8 @@ DIE_NODE(ps_dcs_22): power-controller@430 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_22);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc5)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_23): power-controller@440 {
@@ -714,8 +714,8 @@ DIE_NODE(ps_dcs_23): power-controller@440 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_23);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc5)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_28): power-controller@450 {
@@ -724,8 +724,8 @@ DIE_NODE(ps_dcs_28): power-controller@450 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_28);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc7)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_29): power-controller@460 {
@@ -734,8 +734,8 @@ DIE_NODE(ps_dcs_29): power-controller@460 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_29);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc7)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_30): power-controller@470 {
@@ -744,8 +744,8 @@ DIE_NODE(ps_dcs_30): power-controller@470 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_30);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc7)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_dcs_31): power-controller@480 {
@@ -754,8 +754,8 @@ DIE_NODE(ps_dcs_31): power-controller@480 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_31);
-		apple,always-on; /* LPDDR5 interface */
 		power-domains = <&DIE_NODE(ps_amcc7)>;
+		apple,always-on; /* LPDDR5 interface */
 	};
 
 	DIE_NODE(ps_mca0): power-controller@4e8 {
@@ -935,8 +935,8 @@ DIE_NODE(ps_sep): power-controller@c00 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(sep);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc4_lw0)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_isp_cpu): power-controller@4008 {
@@ -1089,8 +1089,8 @@ DIE_NODE(ps_pms_c1ppt): power-controller@128 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(pms_c1ppt);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_soc_dpe)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_pmgr_soc_ocla): power-controller@130 {
@@ -1173,8 +1173,8 @@ DIE_NODE(ps_amcc0): power-controller@180 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(amcc0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afc)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_amcc2): power-controller@190 {
@@ -1183,8 +1183,8 @@ DIE_NODE(ps_amcc2): power-controller@190 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(amcc2);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afc)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_amcc4): power-controller@1a0 {
@@ -1193,8 +1193,8 @@ DIE_NODE(ps_amcc4): power-controller@1a0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(amcc4);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afc)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_amcc6): power-controller@1b0 {
@@ -1203,8 +1203,8 @@ DIE_NODE(ps_amcc6): power-controller@1b0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(amcc6);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afc)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_00): power-controller@1c0 {
@@ -1213,8 +1213,8 @@ DIE_NODE(ps_dcs_00): power-controller@1c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_00);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc0)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_01): power-controller@1d0 {
@@ -1223,8 +1223,8 @@ DIE_NODE(ps_dcs_01): power-controller@1d0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_01);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc0)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_02): power-controller@1e0 {
@@ -1233,8 +1233,8 @@ DIE_NODE(ps_dcs_02): power-controller@1e0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_02);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc0)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_03): power-controller@1f0 {
@@ -1243,8 +1243,8 @@ DIE_NODE(ps_dcs_03): power-controller@1f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_03);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc0)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_08): power-controller@200 {
@@ -1253,8 +1253,8 @@ DIE_NODE(ps_dcs_08): power-controller@200 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_08);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc2)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_09): power-controller@210 {
@@ -1263,8 +1263,8 @@ DIE_NODE(ps_dcs_09): power-controller@210 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_09);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc2)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_10): power-controller@220 {
@@ -1273,8 +1273,8 @@ DIE_NODE(ps_dcs_10): power-controller@220 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_10);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc2)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_11): power-controller@230 {
@@ -1283,8 +1283,8 @@ DIE_NODE(ps_dcs_11): power-controller@230 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_11);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc2)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_16): power-controller@240 {
@@ -1293,8 +1293,8 @@ DIE_NODE(ps_dcs_16): power-controller@240 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_16);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc4)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_17): power-controller@250 {
@@ -1303,8 +1303,8 @@ DIE_NODE(ps_dcs_17): power-controller@250 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_17);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc4)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_18): power-controller@260 {
@@ -1313,8 +1313,8 @@ DIE_NODE(ps_dcs_18): power-controller@260 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_18);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc4)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_19): power-controller@270 {
@@ -1323,8 +1323,8 @@ DIE_NODE(ps_dcs_19): power-controller@270 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_19);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc4)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_24): power-controller@280 {
@@ -1333,8 +1333,8 @@ DIE_NODE(ps_dcs_24): power-controller@280 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_24);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc6)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_25): power-controller@290 {
@@ -1343,8 +1343,8 @@ DIE_NODE(ps_dcs_25): power-controller@290 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_25);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc6)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_dcs_26): power-controller@2a0 {
@@ -1353,8 +1353,8 @@ DIE_NODE(ps_dcs_26): power-controller@2a0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_26);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc6)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afi): power-controller@2b0 {
@@ -1372,8 +1372,8 @@ DIE_NODE(ps_dcs_27): power-controller@2c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(dcs_27);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_amcc6)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afi_d2d_0): power-controller@2d0 {
@@ -1448,8 +1448,8 @@ DIE_NODE(ps_afnc1_ioa): power-controller@330 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_ioa);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc0_ioa): power-controller@340 {
@@ -1458,8 +1458,8 @@ DIE_NODE(ps_afnc0_ioa): power-controller@340 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_ioa);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_ioa): power-controller@350 {
@@ -1468,8 +1468,8 @@ DIE_NODE(ps_afnc2_ioa): power-controller@350 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_ioa);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc7_ioa): power-controller@360 {
@@ -1478,8 +1478,8 @@ DIE_NODE(ps_afnc7_ioa): power-controller@360 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc7_ioa);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afi)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc1_ls): power-controller@370 {
@@ -1488,8 +1488,8 @@ DIE_NODE(ps_afnc1_ls): power-controller@370 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc1_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc0_ls): power-controller@380 {
@@ -1498,8 +1498,8 @@ DIE_NODE(ps_afnc0_ls): power-controller@380 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc0_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_ls): power-controller@390 {
@@ -1508,8 +1508,8 @@ DIE_NODE(ps_afnc2_ls): power-controller@390 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc2_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc7_ls): power-controller@3a0 {
@@ -1518,8 +1518,8 @@ DIE_NODE(ps_afnc7_ls): power-controller@3a0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc7_ls);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc7_ioa)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc1_lw0): power-controller@3b0 {
@@ -1528,8 +1528,8 @@ DIE_NODE(ps_afnc1_lw0): power-controller@3b0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc1_lw1): power-controller@3c0 {
@@ -1538,8 +1538,8 @@ DIE_NODE(ps_afnc1_lw1): power-controller@3c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc1_lw1);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc1_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc0_lw0): power-controller@3d0 {
@@ -1548,8 +1548,8 @@ DIE_NODE(ps_afnc0_lw0): power-controller@3d0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc0_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc0_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_lw0): power-controller@3e0 {
@@ -1558,8 +1558,8 @@ DIE_NODE(ps_afnc2_lw0): power-controller@3e0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_lw0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc2_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc2_lw1): power-controller@3f0 {
@@ -1568,8 +1568,8 @@ DIE_NODE(ps_afnc2_lw1): power-controller@3f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(afnc2_lw1);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_afnc2_ls)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_afnc7_lw0): power-controller@400 {
@@ -2027,8 +2027,8 @@ DIE_NODE(ps_nub_spmi0): power-controller@68 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(nub_spmi0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_spmi_ahb_fab)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_nub_spmi_a0): power-controller@70 {
@@ -2123,8 +2123,8 @@ DIE_NODE(ps_nub_spmi1): power-controller@c8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(nub_spmi1);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_spmi_ahb_fab)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_atc0_usb_aon): power-controller@d0 {
@@ -2165,8 +2165,8 @@ DIE_NODE(ps_nub_spmi2): power-controller@f0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(nub_spmi2);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_spmi_ahb_fab)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_nub_spmi3): power-controller@f8 {
@@ -2175,8 +2175,8 @@ DIE_NODE(ps_nub_spmi3): power-controller@f8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(nub_spmi3);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_spmi_ahb_fab)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_nub_spmi4): power-controller@100 {
@@ -2185,8 +2185,8 @@ DIE_NODE(ps_nub_spmi4): power-controller@100 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(nub_spmi4);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_spmi_ahb_fab)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_nub_spmi5): power-controller@108 {
@@ -2195,8 +2195,8 @@ DIE_NODE(ps_nub_spmi5): power-controller@108 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(nub_spmi5);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_spmi_ahb_fab)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_nub_fabric): power-controller@110 {
@@ -2270,8 +2270,8 @@ DIE_NODE(ps_mtp_fabric): power-controller@2000 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_fabric);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_nub_fabric)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_gpio): power-controller@2008 {
@@ -2280,8 +2280,8 @@ DIE_NODE(ps_mtp_gpio): power-controller@2008 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_gpio);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_base): power-controller@2010 {
@@ -2290,8 +2290,8 @@ DIE_NODE(ps_mtp_base): power-controller@2010 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_base);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_periph): power-controller@2018 {
@@ -2300,8 +2300,8 @@ DIE_NODE(ps_mtp_periph): power-controller@2018 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_periph);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_uart0): power-controller@2020 {
@@ -2310,8 +2310,8 @@ DIE_NODE(ps_mtp_uart0): power-controller@2020 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_uart0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_cpu): power-controller@2028 {
@@ -2320,8 +2320,8 @@ DIE_NODE(ps_mtp_cpu): power-controller@2028 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_cpu);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_scm_fabric): power-controller@2030 {
@@ -2330,8 +2330,8 @@ DIE_NODE(ps_mtp_scm_fabric): power-controller@2030 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_scm_fabric);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_periph)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_spi0): power-controller@2038 {
@@ -2340,8 +2340,8 @@ DIE_NODE(ps_mtp_spi0): power-controller@2038 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_spi0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>, <&DIE_NODE(ps_mtp_periph)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_i2cm0): power-controller@2040 {
@@ -2350,8 +2350,8 @@ DIE_NODE(ps_mtp_i2cm0): power-controller@2040 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_i2cm0);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>, <&DIE_NODE(ps_mtp_periph)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_sram): power-controller@2048 {
@@ -2360,8 +2360,8 @@ DIE_NODE(ps_mtp_sram): power-controller@2048 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_sram);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_cpu)>, <&DIE_NODE(ps_mtp_scm_fabric)>;
+		apple,always-on;
 	};
 
 	DIE_NODE(ps_mtp_dma): power-controller@2050 {
@@ -2370,8 +2370,8 @@ DIE_NODE(ps_mtp_dma): power-controller@2050 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = DIE_LABEL(mtp_dma);
-		apple,always-on;
 		power-domains = <&DIE_NODE(ps_mtp_fabric)>, <&DIE_NODE(ps_mtp_sram)>;
+		apple,always-on;
 	};
 #endif
 };
diff --git a/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi b/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
index fef8a4058f14..57f3e5a4ef89 100644
--- a/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
@@ -1067,8 +1067,8 @@ ps_debug_usb: power-controller@b8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "debug_usb";
-		apple,always-on; /* Core AON device */
 		power-domains = <&ps_debug>;
+		apple,always-on; /* Core AON device */
 	};
 
 	ps_debug_auth: power-controller@c0 {
@@ -1077,8 +1077,8 @@ ps_debug_auth: power-controller@c0 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "debug_auth";
-		apple,always-on; /* Core AON device */
 		power-domains = <&ps_debug>;
+		apple,always-on; /* Core AON device */
 	};
 
 	ps_nub_spmi1: power-controller@68 {
diff --git a/arch/arm64/boot/dts/apple/t8112-pmgr.dtsi b/arch/arm64/boot/dts/apple/t8112-pmgr.dtsi
index 7c050c6f2707..d3f6855789d1 100644
--- a/arch/arm64/boot/dts/apple/t8112-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112-pmgr.dtsi
@@ -166,8 +166,8 @@ ps_sio: power-controller@1b8 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "sio";
-		apple,always-on;
 		power-domains = <&ps_sio_busif>;
+		apple,always-on;
 	};
 
 	ps_sio_cpu: power-controller@1c0 {

---
base-commit: 7809dfc2040bd6b8808da2cb7b8ce429ce3df946
change-id: 20261114-pmgr-dt-fixes-7d5547d3c55e

Best regards,
--  
Sven Peter <sven@kernel.org>

