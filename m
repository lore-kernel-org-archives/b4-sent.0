From: David Heidelberg <david@ixit.cz>
Date: Sun, 06 Sep 2026 02:41:15 +0200
Subject: [PATCH RFC 4/4] arm64: dts: qcom: sdm670-google: Add modemsmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-modemsmem-v1-4-a3634b553841@ixit.cz>
References: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
In-Reply-To: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Acayan <mailingradian@gmail.com>, Petr Vorel <petr.vorel@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1040; i=david@ixit.cz;
 h=from:subject:message-id; bh=TWhq237rZhu1dOgSbAfHXHmc82yvCd23tTIcG8XeM4Y=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnLavPpWNaZfkKWF76bCFYzF1GnMpyQalCsKCF
 PD96WyDkxuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapy2rwAKCRBgAj/E00kg
 cneXEADEztAkrJN/obtgTy+goU4i3hQ35Ps3C2kYGdyQscbWK6dJp0WxpnUI05+wQk61Pf53DYh
 8JjDb6qqVM1UtpK/2nIiw0LTItZu12fuBCq9y+PJFGiFdb/qMXe6FZlsXVcaxjkEnktggI0IwkB
 H2aCmPeU8qf28YCGOvTQF8djBgAeCg3rdq4MPLTVcOC/sWBDabJZoK6obixqYph34tNDvS9Hxyt
 wp1H5WkAtUubyiV4BfqQHYn8T/qj49taWd5+4VlRF9iwBF4j/hskzEV9aDNwTBezeIM7ZoQ/qoX
 9lVF99tsTSaTfBMLW2DfrwMX/9W/3/V6mABKIrh/0RXU0MC9u34wvZuq1OWUIW31NBmhSCMrbzJ
 vHbVqsntooUkb/bvRziHnaxPTDXHl33brhbHv2nFNWOejI6+se5PGpwW/gvWpSHai0fXTRQKCZm
 CwYHGO4i767HgYW96sJpMVekSJyssIXGjEyvLcETLrZOyH37ZGqskbQkstma9XkxaZjNNyb0cNU
 huRNCf84fqcM4CFnye4g9MaGagWLfrP4Soo+0qh3qU2jyYo6Z03XbcHOEBzo/4HwNlKNUVMHMmO
 a5XV25IRY8p4acKTACABfVxLiV20gmted+a3GL8svlihI8iZAPE6taP4XwGjFyCqnVx14COIlTC
 NeBbN5oUj4K8Zfw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Richard Acayan <mailingradian@gmail.com>

The Pixel 3a modem needs the modemsmem client. Add it in the device
tree so the modem can properly boot.

Signed-off-by: Richard Acayan <mailingradian@gmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
index b4854801a5f5e..4604c4eb2192a 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -61,16 +61,21 @@ gpio-keys {
 
 		key-vol-up {
 			label = "Volume Up";
 			linux,code = <KEY_VOLUMEUP>;
 			gpios = <&pm660l_gpios 7 GPIO_ACTIVE_LOW>;
 		};
 	};
 
+	modemsmem {
+		compatible = "google,modemsmem";
+		qcom,smem-id = <134>;
+	};
+
 	reserved-memory {
 		#address-cells = <2>;
 		#size-cells = <2>;
 
 		mpss_region: mpss@8b000000 {
 			reg = <0 0x8b000000 0 0x9800000>;
 			no-map;
 		};

-- 
2.55.0

