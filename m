From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:44 +0100
Subject: [PATCH v2 11/12] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-11-3c77a72b280a@ixit.cz>
References: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
In-Reply-To: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1319; i=david@ixit.cz;
 h=from:subject:message-id; bh=/Lj3TGFexa5AfzuS/I1Uhtld+K5vTju4obeOh3yWZrc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+XlZGDgGZoz0iSr3s6ex4mRpEIhqUZGBxp+
 1ZJCxpTckeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flwAKCRBgAj/E00kg
 cq+EEADLvJzKhZRpu+5LyYC9tSlFmKR0zlyaDNa2Mj6LtKIDkysLAiI20OPDn3NsKzhV7zLrzpI
 3mHCEwoZi4IhgrpTsdnWZQ85lJr2UydKl8dtn0tV2Fmtlj0udVyEIW89kwxBFuedvluPYVjX4eq
 ynSJmSNPNm3o4Tqj7mCUAZ5KpzZj4pSA6q8+Iv+bZYxW5whj4YYEkbXosEKAmtH2ratIIHQZ+ha
 hGDNxJfefCTEmz0fGctH1h0yhfWzEADXsh1F+B1YDQJE/8opCZVB1vYeEd2TOQj+m8jG0SMhMrP
 9B8USfeseQsjXBfkqQetQZplwto3brFCt4gaMaSiwxzbhhUsZ4gnnFAyKws/LbYzp0sVtyoH5So
 +/ijmXpCTFoC9jNf+cAeuQxSMQdgJBKxDbMl4z/fBRnb/ErMh7b3uGxZgs42g1+7pnGGkA6HKvh
 XYwBLLfyYScLcksaw6dcVVlAW7aJwfHTRkRq1K3EShcZJRlcJpkozrB/jLCA9lSjQiZOXA7YQz2
 FicoGv9jBsgA1MU8lo8UuMql1X9PrRsqoqpSUpRS6E+PLgJjwvdf9xIvLyFPwq8Az4UKWP2VUP7
 kRzElwwHW5Se2Huvqczo39yHcNr1bp4pyzN1GKfDqcKfBXI+4ig+xLxKWQM36MtupP4J9KGjedz
 qD0LjtOki2MBOpA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On this device, vbus was setup and switched off by the charger driver.
Enable proper driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index d57851b0b9419..aab5738253914 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -418,16 +418,23 @@ led-1 {
 	};
 };
 
 &pm8998_resin {
 	linux,code = <KEY_VOLUMEDOWN>;
 	status = "okay";
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 /* QUAT I2S Uses 1 I2S SD Line for audio on TAS2559/60 amplifiers */
 &q6afedai {
 	dai@22 {
 		reg = <QUATERNARY_MI2S_RX>;
 		qcom,sd-lines = <0>;
 	};
 };
 
@@ -682,9 +689,8 @@ &wifi {
 	vdd-1.8-xo-supply = <&vreg_l7a_1p8>;
 	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
 	qcom,calibration-variant = "xiaomi_beryllium";
 	qcom,snoc-host-cap-skip-quirk;
 };
-

-- 
2.55.0

