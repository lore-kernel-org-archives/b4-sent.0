From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 10 May 2025 07:44:45 +0000
Subject: [PATCH 5/7] arm64: dts: apple: t8103: Add eFuses node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250510-nvmem-dt-v1-5-eccfa6e33f6a@svenpeter.dev>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2966; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=hvAqTufzhOojxJ9ZjRR62jKrJGngJmyVl4diuLr5gAM=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4Y8C6PszTcHJsasFHb3y2r5eUBXdZ3l+biMmvdXn/NGr
 A526FTuKGVhEONgkBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEzEz4GRYXPxw/MHpnEdzz83
 xXvuhzVvCiLf954QmCH2um/q4dmLarIY/sfzVcZsXxx79s9Pww0MTHvv3Cmp3rMgY9vq/X7bTJe
 n2zMCAA==
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the eFuse controller and the nvmem cells required for both Type-C
PHYs.

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 arch/arm64/boot/dts/apple/t8103.dtsi | 102 +++++++++++++++++++++++++++++++++++
 1 file changed, 102 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8103.dtsi b/arch/arm64/boot/dts/apple/t8103.dtsi
index 97b6a067394e311ed19392a34237c74936dbb7d7..e7ca9204a9a2fedc70111fdd8ed3f7e8e4f8d266 100644
--- a/arch/arm64/boot/dts/apple/t8103.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103.dtsi
@@ -854,6 +854,108 @@ nvme@27bcc0000 {
 			resets = <&ps_ans2>;
 		};
 
+		efuse@23d2bc000 {
+			compatible = "apple,t8103-efuses", "apple,efuses";
+			reg = <0x2 0x3d2bc000 0x0 0x1000>;
+			#address-cells = <1>;
+			#size-cells = <1>;
+
+			atcphy0_auspll_rodco_bias_adjust: efuse@430,26 {
+				reg = <0x430 4>;
+				bits = <26 3>;
+			};
+
+			atcphy0_auspll_rodco_encap: efuse@430,29 {
+				reg = <0x430 4>;
+				bits = <29 2>;
+			};
+
+			atcphy0_auspll_dtc_vreg_adjust: efuse@430,31 {
+				reg = <0x430 8>;
+				bits = <31 3>;
+			};
+
+			atcphy0_auspll_fracn_dll_start_capcode: efuse@434,2 {
+				reg = <0x434 4>;
+				bits = <2 2>;
+			};
+
+			atcphy0_aus_cmn_shm_vreg_trim: efuse@434,4 {
+				reg = <0x434 4>;
+				bits = <4 5>;
+			};
+
+			atcphy0_cio3pll_dco_coarsebin0: efuse@434,9 {
+				reg = <0x434 4>;
+				bits = <9 6>;
+			};
+
+			atcphy0_cio3pll_dco_coarsebin1: efuse@434,15 {
+				reg = <0x434 4>;
+				bits = <15 6>;
+			};
+
+			atcphy0_cio3pll_dll_start_capcode: efuse@434,21 {
+				reg = <0x434 4>;
+				bits = <21 2>;
+			};
+
+			atcphy0_cio3pll_dtc_vreg_adjust: efuse@434,23 {
+				reg = <0x434 0x4>;
+				bits = <23 3>;
+			};
+
+			atcphy1_auspll_rodco_bias_adjust: efuse@438,4 {
+				reg = <0x438 4>;
+				bits = <4 3>;
+			};
+
+			atcphy1_auspll_rodco_encap: efuse@438,7 {
+				reg = <0x438 4>;
+				bits = <7 2>;
+			};
+
+			atcphy1_auspll_dtc_vreg_adjust: efuse@438,9 {
+				reg = <0x438 4>;
+				bits = <9 3>;
+			};
+
+			atcphy1_auspll_fracn_dll_start_capcode: efuse@438,12 {
+				reg = <0x438 4>;
+				bits = <12 2>;
+			};
+
+			atcphy1_aus_cmn_shm_vreg_trim: efuse@438,14 {
+				reg = <0x438 4>;
+				bits = <14 5>;
+			};
+
+			atcphy1_cio3pll_dco_coarsebin0: efuse@438,19 {
+				reg = <0x438 4>;
+				bits = <19 6>;
+			};
+
+			atcphy1_cio3pll_dco_coarsebin1: efuse@438,25 {
+				reg = <0x438 4>;
+				bits = <25 6>;
+			};
+
+			atcphy1_cio3pll_dll_start_capcode: efuse@438,31 {
+				reg = <0x438 4>;
+				bits = <31 1>;
+			};
+
+			atcphy1_cio3pll_dll_start_capcode_workaround: efuse@43c,0 {
+				reg = <0x43c 0x4>;
+				bits = <0 1>;
+			};
+
+			atcphy1_cio3pll_dtc_vreg_adjust: efuse@43c,1 {
+				reg = <0x43c 0x4>;
+				bits = <1 3>;
+			};
+		};
+
 		pcie0_dart_0: iommu@681008000 {
 			compatible = "apple,t8103-dart";
 			reg = <0x6 0x81008000 0x0 0x4000>;

-- 
2.34.1

