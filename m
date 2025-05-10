From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 10 May 2025 07:44:47 +0000
Subject: [PATCH 7/7] arm64: dts: apple: t8112: Add eFuses node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250510-nvmem-dt-v1-7-eccfa6e33f6a@svenpeter.dev>
References: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
In-Reply-To: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
To: Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2946; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=j8UAIvDfj4+sxfGUjSBnpN2Tc+COrCSgMqHTgCD6qaE=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4Y8C5Pvvb3nd1S1va7TWWZrYM+v6bqTeS8fM9ssXjbtb
 PmbkmodpSwMYhwMsmKKLNv325s+efhGcOmmS+9h5rAygQxh4OIUgImEBjH8FXX64lD5sPT+0iwf
 owVXjNfdcTAz+rX278Qvz60knwV4ODEyrGq35UgWbrn35/0rpRd8fzw/vs7JcPXXSZl47aTtUvH
 fPAA=
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Janne Grunau <j@jannau.net>

Add the eFuse controller and the nvmem cells required for both Type-C
PHYs

Signed-off-by: Janne Grunau <j@jannau.net>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 arch/arm64/boot/dts/apple/t8112.dtsi | 97 ++++++++++++++++++++++++++++++++++++
 1 file changed, 97 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8112.dtsi b/arch/arm64/boot/dts/apple/t8112.dtsi
index d9b966d68e4fae2dfb21d6fb7a97ebba81643ae8..4dec6415ef73e922dd574997569ad0e6acbc9658 100644
--- a/arch/arm64/boot/dts/apple/t8112.dtsi
+++ b/arch/arm64/boot/dts/apple/t8112.dtsi
@@ -782,6 +782,103 @@ wdt: watchdog@23d2b0000 {
 			interrupts = <AIC_IRQ 379 IRQ_TYPE_LEVEL_HIGH>;
 		};
 
+		efuse@23d2c8000 {
+			compatible = "apple,t8112-efuses", "apple,efuses";
+			reg = <0x2 0x3d2c8000 0x0 0x1000>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			atcphy0_auspll_rodco_bias_adjust: efuse@480,20 {
+				reg = <0x480 4>;
+				bits = <20 3>;
+			};
+
+			atcphy0_auspll_rodco_encap: efuse@480,23 {
+				reg = <0x480 4>;
+				bits = <23 2>;
+			};
+
+			atcphy0_auspll_dtc_vreg_adjust: efuse@480,25 {
+				reg = <0x480 4>;
+				bits = <25 3>;
+			};
+
+			atcphy0_auspll_fracn_dll_start_capcode: efuse@480,28 {
+				reg = <0x480 4>;
+				bits = <28 2>;
+			};
+
+			atcphy0_aus_cmn_shm_vreg_trim: efuse@480,30 {
+				reg = <0x480 8>;
+				bits = <30 5>;
+			};
+
+			atcphy0_cio3pll_dco_coarsebin0: efuse@484,3 {
+				reg = <0x484 4>;
+				bits = <3 6>;
+			};
+
+			atcphy0_cio3pll_dco_coarsebin1: efuse@484,9 {
+				reg = <0x484 4>;
+				bits = <9 6>;
+			};
+
+			atcphy0_cio3pll_dll_start_capcode: efuse@484,15 {
+				reg = <0x484 4>;
+				bits = <15 2>;
+			};
+
+			atcphy0_cio3pll_dtc_vreg_adjust: efuse@484,17 {
+				reg = <0x484 0x4>;
+				bits = <17 3>;
+			};
+
+			atcphy1_auspll_rodco_bias_adjust: efuse@484,30 {
+				reg = <0x484 8>;
+				bits = <30 3>;
+			};
+
+			atcphy1_auspll_rodco_encap: efuse@488,1 {
+				reg = <0x488 8>;
+				bits = <1 2>;
+			};
+
+			atcphy1_auspll_dtc_vreg_adjust: efuse@488,3 {
+				reg = <0x488 4>;
+				bits = <3 3>;
+			};
+
+			atcphy1_auspll_fracn_dll_start_capcode: efuse@488,6 {
+				reg = <0x488 4>;
+				bits = <6 2>;
+			};
+
+			atcphy1_aus_cmn_shm_vreg_trim: efuse@488,8 {
+				reg = <0x488 4>;
+				bits = <8 5>;
+			};
+
+			atcphy1_cio3pll_dco_coarsebin0: efuse@488,13 {
+				reg = <0x488 4>;
+				bits = <13 6>;
+			};
+
+			atcphy1_cio3pll_dco_coarsebin1: efuse@488,19 {
+				reg = <0x488 4>;
+				bits = <19 6>;
+			};
+
+			atcphy1_cio3pll_dll_start_capcode: efuse@488,25 {
+				reg = <0x488 4>;
+				bits = <25 2>;
+			};
+
+			atcphy1_cio3pll_dtc_vreg_adjust: efuse@488,27 {
+				reg = <0x488 0x4>;
+				bits = <27 3>;
+			};
+		};
+
 		pinctrl_smc: pinctrl@23e820000 {
 			compatible = "apple,t8112-pinctrl", "apple,pinctrl";
 			reg = <0x2 0x3e820000 0x0 0x4000>;

-- 
2.34.1

