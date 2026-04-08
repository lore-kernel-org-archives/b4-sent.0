From: David Heidelberg <david@ixit.cz>
Date: Wed, 08 Apr 2026 19:34:33 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-oneplus: Update compatible to
 include model
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-synaptics-rmi4-dt-v1-2-2d32bacce673@ixit.cz>
References: <20260408-synaptics-rmi4-dt-v1-0-2d32bacce673@ixit.cz>
In-Reply-To: <20260408-synaptics-rmi4-dt-v1-0-2d32bacce673@ixit.cz>
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
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=871; i=david@ixit.cz;
 h=from:subject:message-id; bh=H0Dnj26qpNUOEIXbqprRGTPK5SZ+iz0wAv+RBadPJ9g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1pGnCIps7eqk4gak7u3iaLt7/lptFl2iXRu8i
 DY9s5/48tmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadaRpwAKCRBgAj/E00kg
 cuzVEACrAenxgZsjeY2unlTkTXQC8s4FYD4NqD1VonQ+I1CMGZbama3svy2jDkHLn1zL3dsyE9q
 yRldJVqMFeaZf2l6yAN5jU70JsoubOmbPtEF4j7mqPOaayYEone9n8LMU6sdD1PHQ01X2x6iQie
 aNhIoQky3SxY6Np1nb67a9R/Rv2a6r3105d9a5t6bLRgiyxkSJSBqO0dQpYZco2qtdC7t3SWOEg
 Ka0JdQTZTS1GsCKrza2D51K6xL/IHnw9JjzDzncBjt5VF6Lo6GgoF4NWjoAi0KUwQKW4440NYAP
 F16wDNQ8IUGOOFxsWasMh7Yw3qH/nXmyiSIE0hdD/Uz+DZVgs932IrzdGV5Z/46sdmxwwKJxByz
 Vow2AUobPuCDTxl0tEKGk2P4RBzQlUs13WjIlnQp8WtzKLm8XwP3yoUzHUYsq+8PjpzrlFwUIPB
 o9d74TiLsvhOOdkmS6flc/0muUk2MSJxbOj8YkuMbjRQcsck+6j4R0ZXAvtpT3rC7/HKmL+VPdc
 DKnpW8SY9+UROq15Qirjh/YTUPOs7nD/U+84wxcWkNjuLU57/+6vdGuyUadtGvb0+P6q/nRZchV
 POLZ0VdI0L8FpYUm2950DlCT2orYN8mTy373GYPeAEjIen06SChA4zq4h5elCJdjNJJohHZYSuA
 Hp1DX1lhuY5oWng==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We know the driver is reporting s3706b, introduce the compatible so we
can more easily introduce quirks for weird touchscreen replacements in
followup series.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 6b7378cf4d493..148164d456a5a 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -480,7 +480,7 @@ &i2c12 {
 	clock-frequency = <400000>;
 
 	synaptics-rmi4-i2c@20 {
-		compatible = "syna,rmi4-i2c";
+		compatible = "syna,rmi4-s3706b", "syna,rmi4-i2c";
 		reg = <0x20>;
 		#address-cells = <1>;
 		#size-cells = <0>;

-- 
2.53.0

