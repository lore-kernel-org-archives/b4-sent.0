From: Sam Day <me@samcday.com>
Date: Tue, 16 Jun 2026 15:27:12 +1000
Subject: [PATCH] arm64: dts: qcom: sdm845-oneplus: add panel rails to
 simplefb
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-sdm845-oneplus-simplefb-regulators-v1-1-1db1804acef6@samcday.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3NQQqEMAxA0atI1gZUtOhcZXDhtKkGaluScRgQ7
 25x+Tb/n6AkTAqv6gShHyunWNDWFdhtiSshu2Loms40pjWobh/7AVOkHA5F5T0H8h8UWo+wfJM
 oejuNdnDemYmghLKQ5/8zec/XdQPlhJp+dAAAAA==
X-Change-ID: 20260616-sdm845-oneplus-simplefb-regulators-fc98c5dfd69e
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781587638; l=1167;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=zy9XPoerjyypgnPLHLVXSffI5hSRg9aWPbyKM9SQImM=;
 b=GjKaOznZOn4JpE2UCxKDFsFD4fC83SiGMBofvlvhXYFrHiA7MLo4D2ZI5WCJxCn9C5GBzxHvE
 4tWK9W3sPycC4Oo9OV5+uLR5tV3SYejpQl/SFfHnyeQZIUv5LsJ7FrA
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These regulators are marked regulator-boot-on, but that doesn't
guarantee they'll stay alive as long as the simplefb does. Adding the
explicit supplies ensures that booting with MDSS disabled doesn't
switch the panel off 30 seconds after boot.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index a6c2519a418d9..fc6ac8668a7bd 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -75,6 +75,9 @@ chosen {
 		framebuffer: framebuffer {
 			compatible = "simple-framebuffer";
 			memory-region = <&cont_splash_mem>;
+			vddio-supply = <&vreg_l14a_1p88>;
+			vci-supply = <&panel_vci_3v3>;
+			poc-supply = <&panel_vddi_poc_1p8>;
 
 			format = "a8r8g8b8";
 			stride = <(1080 * 4)>;

---
base-commit: 8d6dbbbe3ba62de0a63e962ee004afb848c8e3ac
change-id: 20260616-sdm845-oneplus-simplefb-regulators-fc98c5dfd69e

Best regards,
-- 
Sam Day <me@samcday.com>

