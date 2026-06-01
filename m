From: =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
Date: Mon, 01 Jun 2026 18:54:02 +0200
Subject: [PATCH v3 3/3] arm64: dts: qcom: sdm670-google-common: enable
 debug uart
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-3-6fdcd669364e@postmarketos.org>
References: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-0-6fdcd669364e@postmarketos.org>
In-Reply-To: <20260601-pabloyoyoista-debug-uart-on-rdacayan-next-v3-0-6fdcd669364e@postmarketos.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Pablo_Correa_G=C3=B3mez?= <pabloyoyoista@postmarketos.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1252;
 i=pabloyoyoista@postmarketos.org; h=from:subject:message-id;
 bh=sDlGpWG4oSXHkFM0Uy4CwwkhUF4Wja0JdBSYWu4Qm+A=;
 b=owEBbQKS/ZANAwAKAXo0JWX/Y195AcsmYgBqHbk0aUupqcJ76Jj+5ygapbtSikJWiSsQHmW6v
 oQ26QNTHEeJAjMEAAEKAB0WIQS9CheUSi6o/ykTCaJ6NCVl/2NfeQUCah25NAAKCRB6NCVl/2Nf
 eZtzD/9rfIOSt0VxsAPVWHYWB1YolQUoA2I8/SH0weLNEC3qcG5ykfhuGI6l019AphyJlV78tJ+
 a/vn2pmnu9HTtFaUPc3jYOREQ64ktBdkfpsyYYLojxjRiu1byfUl8XVoRs9eww7b+HHokHEzKYm
 rt1eYS1LZMEytOlOyzv/end7+pNb0x7+zcPqxw2GvVrs3XpdYOI3Xz5aWqyJTHFRGp0Oap3v0BK
 iAFK1O0CV3QGU6tToafGuRCdgpghYZ+2unAMakhrStnDXS7Gvykc55H6j3DQqM5Kh0ezdFlYBk1
 YUAnEvdEtRZV87Fzu/6DDqv9save7LruZnuybXBCyNLYbG6jbfLzouZk2khDD/22Q+p7toTWtLb
 A26N2N8ElasnnH4srHugLHwoW7wdaxC44kb0UjrZd8i/BLTHbAeR/fFZEs53y+wGEtOQ8jGNtNB
 IsYwmETZ3mDwTJZDE4/qaw3ZC4oQOszJWfPFB9OAbb8wahkP2Npmi+JRfZcJ1O/AaYr4AuYsuKo
 1WeHuOw5MxUhz6by9IWajlm11MC/qUohpvky8JC1VxfDjyPbjDBNKIjZNRn4lmPouiiNMQ5JFin
 juNZeyVp7WHIPPZb98/F1haErtgBWzLdOVtLcnrTPVZGBru33+LbX+S8NiqYfRzPZtQeC/mPu1P
 52WSCokLY7XMDvA==
X-Developer-Key: i=pabloyoyoista@postmarketos.org; a=openpgp;
 fpr=BD0A17944A2EA8FF291309A27A342565FF635F79
X-Endpoint-Received: by B4 Relay for pabloyoyoista@postmarketos.org/default with auth_id=698
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This has been tested on the Pixel 3a with USB Cereal board

Depends on
https://lore.kernel.org/all/20260310002606.16413-5-mailingradian@gmail.com/

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

