From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 10 May 2025 07:44:46 +0000
Subject: [PATCH 6/7] arm64: dts: apple: t600x: Add eFuses node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250510-nvmem-dt-v1-6-eccfa6e33f6a@svenpeter.dev>
References: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
In-Reply-To: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
To: Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>, R <rqou@berkeley.edu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5131; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=UXt9Kftl5StUn3CgxMRa9JeMUPLGniuUQZkGLH1xy4Y=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4Y8C5O+3b/+NZ/yFSe/v8x6XSOscu3l7y2i51SlC57ce
 1w6j+NURykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiS2oZGe592LK5uNGzPT7a
 6pPlApXby//appyWfWnNwhfb0PzwzleGf7rKts26OSliNzpmiqj8/7k/+WZbhvsuu0Xawm+4pk5
 czAsA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: R <rqou@berkeley.edu>

Add the eFuse controller and the nvmem cells required for all Type-C
PHYs

Signed-off-by: R <rqou@berkeley.edu>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 arch/arm64/boot/dts/apple/t600x-dieX.dtsi | 187 ++++++++++++++++++++++++++++++
 1 file changed, 187 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
index a32ff0c9d7b0c2ec720e9d4cf8e769da6431fbba..22deae50864c88cc7ede73946778c5157e836c9e 100644
--- a/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
+++ b/arch/arm64/boot/dts/apple/t600x-dieX.dtsi
@@ -74,6 +74,193 @@ DIE_NODE(pmgr_mini): power-management@292280000 {
 		reg = <0x2 0x92280000 0 0x4000>;
 	};
 
+	DIE_NODE(efuse): efuse@2922bc000 {
+		compatible = "apple,t6000-efuses", "apple,efuses";
+		reg = <0x2 0x922bc000 0x0 0x2000>;
+		#address-cells = <1>;
+		#size-cells = <1>;
+
+		DIE_NODE(atcphy0_auspll_rodco_bias_adjust): efuse@a10,22 {
+			reg = <0xa10 4>;
+			bits = <22 3>;
+		};
+
+		DIE_NODE(atcphy0_auspll_rodco_encap): efuse@a10,25 {
+			reg = <0xa10 4>;
+			bits = <25 2>;
+		};
+
+		DIE_NODE(atcphy0_auspll_dtc_vreg_adjust): efuse@a10,27 {
+			reg = <0xa10 4>;
+			bits = <27 3>;
+		};
+
+		DIE_NODE(atcphy0_auspll_fracn_dll_start_capcode): efuse@a10,30 {
+			reg = <0xa10 4>;
+			bits = <30 2>;
+		};
+
+		DIE_NODE(atcphy0_aus_cmn_shm_vreg_trim): efuse@a14,0 {
+			reg = <0xa14 4>;
+			bits = <0 5>;
+		};
+
+		DIE_NODE(atcphy0_cio3pll_dco_coarsebin0): efuse@a14,5 {
+			reg = <0xa14 4>;
+			bits = <5 6>;
+		};
+
+		DIE_NODE(atcphy0_cio3pll_dco_coarsebin1): efuse@a14,11 {
+			reg = <0xa14 4>;
+			bits = <11 6>;
+		};
+
+		DIE_NODE(atcphy0_cio3pll_dll_start_capcode): efuse@a14,17 {
+			reg = <0xa14 4>;
+			bits = <17 2>;
+		};
+
+		DIE_NODE(atcphy0_cio3pll_dtc_vreg_adjust): efuse@a14,19 {
+			reg = <0xa14 4>;
+			bits = <19 3>;
+		};
+
+		DIE_NODE(atcphy1_auspll_rodco_bias_adjust): efuse@a18,0 {
+			reg = <0xa18 4>;
+			bits = <0 3>;
+		};
+
+		DIE_NODE(atcphy1_auspll_rodco_encap): efuse@a18,3 {
+			reg = <0xa18 4>;
+			bits = <3 2>;
+		};
+
+		DIE_NODE(atcphy1_auspll_dtc_vreg_adjust): efuse@a18,5 {
+			reg = <0xa18 4>;
+			bits = <5 3>;
+		};
+
+		DIE_NODE(atcphy1_auspll_fracn_dll_start_capcode): efuse@a18,8 {
+			reg = <0xa18 4>;
+			bits = <8 2>;
+		};
+
+		DIE_NODE(atcphy1_aus_cmn_shm_vreg_trim): efuse@a18,10 {
+			reg = <0xa18 4>;
+			bits = <10 5>;
+		};
+
+		DIE_NODE(atcphy1_cio3pll_dco_coarsebin0): efuse@a18,15 {
+			reg = <0xa18 4>;
+			bits = <15 6>;
+		};
+
+		DIE_NODE(atcphy1_cio3pll_dco_coarsebin1): efuse@a18,21 {
+			reg = <0xa18 4>;
+			bits = <21 6>;
+		};
+
+		DIE_NODE(atcphy1_cio3pll_dll_start_capcode): efuse@a18,27 {
+			reg = <0xa18 4>;
+			bits = <27 2>;
+		};
+
+		DIE_NODE(atcphy1_cio3pll_dtc_vreg_adjust): efuse@a18,29 {
+			reg = <0xa18 4>;
+			bits = <29 3>;
+		};
+
+		DIE_NODE(atcphy2_auspll_rodco_bias_adjust): efuse@a1c,10 {
+			reg = <0xa1c 4>;
+			bits = <10 3>;
+		};
+
+		DIE_NODE(atcphy2_auspll_rodco_encap): efuse@a1c,13 {
+			reg = <0xa1c 4>;
+			bits = <13 2>;
+		};
+
+		DIE_NODE(atcphy2_auspll_dtc_vreg_adjust): efuse@a1c,15 {
+			reg = <0xa1c 4>;
+			bits = <15 3>;
+		};
+
+		DIE_NODE(atcphy2_auspll_fracn_dll_start_capcode): efuse@a1c,18 {
+			reg = <0xa1c 4>;
+			bits = <18 2>;
+		};
+
+		DIE_NODE(atcphy2_aus_cmn_shm_vreg_trim): efuse@a1c,20 {
+			reg = <0xa1c 4>;
+			bits = <20 5>;
+		};
+
+		DIE_NODE(atcphy2_cio3pll_dco_coarsebin0): efuse@a1c,25 {
+			reg = <0xa1c 4>;
+			bits = <25 6>;
+		};
+
+		DIE_NODE(atcphy2_cio3pll_dco_coarsebin1): efuse@a1c,31 {
+			reg = <0xa1c 8>;
+			bits = <31 6>;
+		};
+
+		DIE_NODE(atcphy2_cio3pll_dll_start_capcode): efuse@a20,5 {
+			reg = <0xa20 4>;
+			bits = <5 2>;
+		};
+
+		DIE_NODE(atcphy2_cio3pll_dtc_vreg_adjust): efuse@a20,7 {
+			reg = <0xa20 4>;
+			bits = <7 3>;
+		};
+
+		DIE_NODE(atcphy3_auspll_rodco_bias_adjust): efuse@a20,20 {
+			reg = <0xa20 4>;
+			bits = <20 3>;
+		};
+
+		DIE_NODE(atcphy3_auspll_rodco_encap): efuse@a20,23 {
+			reg = <0xa20 4>;
+			bits = <23 2>;
+		};
+
+		DIE_NODE(atcphy3_auspll_dtc_vreg_adjust): efuse@a20,25 {
+			reg = <0xa20 4>;
+			bits = <25 3>;
+		};
+
+		DIE_NODE(atcphy3_auspll_fracn_dll_start_capcode): efuse@a20,28 {
+			reg = <0xa20 4>;
+			bits = <28 2>;
+		};
+
+		DIE_NODE(atcphy3_aus_cmn_shm_vreg_trim): efuse@a20,30 {
+			reg = <0xa20 8>;
+			bits = <30 5>;
+		};
+
+		DIE_NODE(atcphy3_cio3pll_dco_coarsebin0): efuse@a24,3 {
+			reg = <0xa24 4>;
+			bits = <3 6>;
+		};
+
+		DIE_NODE(atcphy3_cio3pll_dco_coarsebin1): efuse@a24,9 {
+			reg = <0xa24 4>;
+			bits = <9 6>;
+		};
+
+		DIE_NODE(atcphy3_cio3pll_dll_start_capcode): efuse@a24,15 {
+			reg = <0xa24 4>;
+			bits = <15 2>;
+		};
+
+		DIE_NODE(atcphy3_cio3pll_dtc_vreg_adjust): efuse@a24,17 {
+			reg = <0xa24 4>;
+			bits = <17 3>;
+		};
+	};
+
 	DIE_NODE(pinctrl_aop): pinctrl@293820000 {
 		compatible = "apple,t6000-pinctrl", "apple,pinctrl";
 		reg = <0x2 0x93820000 0x0 0x4000>;

-- 
2.34.1

