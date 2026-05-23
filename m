From: David Heidelberg <david@ixit.cz>
Date: Sat, 23 May 2026 11:45:35 +0200
Subject: [PATCH v2 2/2] arm64: dts: qcom: sdm845-oneplus: Update compatible
 to include model
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260523-synaptics-rmi4-dt-v2-2-0645122babdc@ixit.cz>
References: <20260523-synaptics-rmi4-dt-v2-0-0645122babdc@ixit.cz>
In-Reply-To: <20260523-synaptics-rmi4-dt-v2-0-0645122babdc@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1137; i=david@ixit.cz;
 h=from:subject:message-id; bh=bXz0ST37brWbiTCA1202uLTw4l3V5FHcLPfgUGhSY+w=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqEXc/9Xo2wQGQuXaJI1BsObKmstt+3LbtWqUbe
 YS7+whGC/qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCahF3PwAKCRBgAj/E00kg
 crUHD/931RtYS8EMQCqn0irqENlTOzT6BQGjcX/+ysD0vgAr1WiibaDCv00HINMYiZq2BtpV37G
 /rQUrQLpDXtpN25+xFam/QB321DhP0gnLHQrdpeKjcWDQexre0h6mYXKbjrxvzwJI1qYScNfGQR
 M31wmVjrBLhtOBv9DE/Mx0YNimpktI7eSME0g1I/EA80YNjUdbIqzU7L3FOqyDbhzNvo5asI2ea
 CEMdkMFDwY/ZKuvY/+glhO9Lu74yz2MJaeFVNo7k7sgnVcAX8jvY1qhaYKRpeDWqK5gtnC7OTz6
 GttyhKjn/NKdqeJOqJLwKiumG57+2UnzOx9cdDSMcAxynkbYIpfMzBi3Ddy+sWZFIdcWcSeJaGD
 WeNlZNUtwmNztw+sgf6szhKVnu1tSyT//6bBVbx9keyvhpZ5HowAfBqvBbFl37GhlelDJem9/ak
 uvDVCrlRjfmTtf2x/GmaGde3I3TL5tOxBEAeb6CSB496k63uE8KGU1QZat48gHQWxIv5hUGbu8D
 r5Vb9bX6JfGjeT/6SyjUy5tLbSV93EyyyyLjY51TGxnSflPn9+if/TT1o5J9r3ua/3uoOV0PQPe
 3L5Bjk49Z1iuh+moUZqcWT6aksqCufZ4vnQXPfY5aayvp1xyiC2rk1s0EZAm4iuL7BpUhs19jk0
 7/J3WMsrRjbPiPw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We know the driver is reporting s3706b, introduce the compatible so we
can more easily introduce quirks for weird touchscreen replacements in
followup series.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 6b7378cf4d493..148164d456a5a 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -475,17 +475,17 @@ bq27441_fg: bq27441-battery@55 {
 	};
 };
 
 &i2c12 {
 	status = "okay";
 	clock-frequency = <400000>;
 
 	synaptics-rmi4-i2c@20 {
-		compatible = "syna,rmi4-i2c";
+		compatible = "syna,rmi4-s3706b", "syna,rmi4-i2c";
 		reg = <0x20>;
 		#address-cells = <1>;
 		#size-cells = <0>;
 		interrupts-extended = <&tlmm 125 IRQ_TYPE_EDGE_FALLING>;
 
 		pinctrl-names = "default";
 		pinctrl-0 = <&ts_default_pins>;
 

-- 
2.53.0

