From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Mon, 01 Jun 2026 18:55:38 +0200
Subject: [PATCH v4 3/3] arm64: dts: qcom: sdm670-google-common: enable
 debug uart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-3-c5d51dd96ca0@postmarketos.org>
References: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-0-c5d51dd96ca0@postmarketos.org>
In-Reply-To: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v4-0-c5d51dd96ca0@postmarketos.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1380;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=4SCoeppOpCMNCW9QJaC0akZ1S9kuDZvEwTxAmO1MfSw=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBqHbmU3k/6IGECCjmflfHZE/w7gi0Do/A89M1wk
 X0BiEzlKV6JAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCah25lAAKCRB6NCVl/2Nf
 eQWQD/4r65jyRvzbZVAsy2CIKafE6k1sNmU1l4dLeOIQvK1OftMoxYlTT3xFcSdretQVlpuW8vJ
 fOUY/6IZRLc+5FI/sycKyxURLi1qb9mIdkI5+QxIJULzlreZEn9ZHspZZ077IK1zlsajYBDYbkB
 9fvvcH+QZAx/WE3gWELmV2ZCLIsSYV+vFdGfGrYnRkjuKUaAps9Y5yT7kyUmJZGuFdfbud0Dl0G
 XT0X8PlX7eg1L7x9oS8OJjGI8wvYGGOOiIvC+SkpHFfc/kgyPifAvdQ4DfWsgLByWt64D+I/Ktu
 39FksOmDglSb3q1lhJ70QbIZcTGRIHafT9BiYtG7V3riJoGY2yLJpoEHP1P5rZWjEodqItWgUdE
 al1IYpJE6wXYidEZols4gODJTGUfZvvgFi6G02R8trJTSDwWnQxi+wxnsIm00b9+4cQPNcpDoP6
 VYaqbjzg0Ac7WJ+ARV1PHmNmW40LqdHYKKIJHrOj0jn0sAOMoJe4o+YtbEfEmd3SxPPfnmQQnzc
 HBSZABfwEX6CrE+/5YlMuCskEoWz6lKRM21/wjqJ9p6RiU45W02VH7pKspW1Er13ld2Xb7+0Nf+
 C6jODEuPcWVrs5FjqQP0/aIwM8s/ah59JhVSaTXXQuLH+L/R8zs2YuO7yWPvID7UhMvncJUXzBQ
 LEthcwKJ9DcO9SA==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This has been tested on the Pixel 3a with USB Cereal board

Depends on
https://lore.kernel.org/all/20260310002606.16413-5-mailingradian@gmail.com/

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Pablo Correa Gómez <pabloyoyoista@postmarketos.org>
---
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
index 0f57b915186b..711664c83b5f 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -26,7 +26,9 @@
 /delete-node/ &gpu_mem;
 
 / {
-	aliases { };
+	aliases {
+		serial0 = &uart12;
+	};
 
 	battery: battery {
 		compatible = "simple-battery";
@@ -622,6 +624,16 @@ &qupv3_id_1 {
 	status = "okay";
 };
 
+&qup_uart12_rx {
+	drive-strength = <2>;
+	bias-pull-up;
+};
+
+&qup_uart12_tx {
+	drive-strength = <2>;
+	bias-disable;
+};
+
 &sdhc_1 {
 	supports-cqe;
 	mmc-hs200-1_8v;
@@ -688,6 +700,10 @@ ts-switch-pins {
 	};
 };
 
+&uart12 {
+	status = "okay";
+};
+
 &usb_1_hsphy {
 	vdd-supply = <&vreg_l1b_0p925>;
 	vdda-pll-supply = <&vreg_l10a_1p8>;

-- 
2.54.0

