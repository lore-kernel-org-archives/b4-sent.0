From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:38:04 +0100
Subject: [PATCH v3 10/12] arm64: dts: qcom: sdm845-lg: Enable vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-10-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1068; i=david@ixit.cz;
 h=from:subject:message-id; bh=PavlMPZO7QvSw1lRn1wTc2SGr5e1GuOSIzQ2zRWRWLw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1bExgVMsWQiDaUrbVQemaVjcDi6CY13LLQN
 iDwaTVRlQqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWwAKCRBgAj/E00kg
 chjqD/4ho11s8jHXBdU2Z9GBgWmUwQNoVS22goJDvSYQlRU9bO4lPjFg8HPd4Di4xloifGKE0Ct
 SNWadEHktihYPuJgvmmkdWrHeEYuAmPSxXY21xgA4taOkNgDp4P2sGKgUOyC+f8mPmLVg2oTEeI
 +Tl1ICXhJ76wGYCmST9eknEETn67xvMgTHW9NWpOXquk/OGdw7XK0zZdmD9L++WLgB1zaFSshf9
 luFNFTZXw123GU1Vj6EOrvfOtyCPCZRnWg1F9f1ivloXmXN7FHieC2Zt8mb2lsZHXMsmZvyNTLF
 Ibm18u7YuNifEku5hsSNrfepK8WDxup+mihW72/3jme/d8G/z9gQJwnXIL21NEeZO5deshdVhYu
 pVu/13W8FsZSzZwm9LGw/xc3pZxpk+uo7Kt9IkfNdTQkUQqBQTe6gFwYJW1UB4KZ26BhKhh1zbU
 dJwCknWWlsvtUsm6UgVA/3ll3VJX3sOILSg+AahSOgNWe6QGSgjbjnt9KzC2rReNUmINLL1XBPZ
 tLmBcz/+rxK8+2DBKZGMAY/L0+WVm/STf/tmsce4KPqyjmuTaGQjBVfzg/3H6/kET+BB/32O5GJ
 3LECbvsfKz/bCETBYIowWO9Z0NSk/xw5ofBYrZ2EWmQrCxZqeylYmiD92+uRm27oSplEcDkT+Rj
 ybCM7bs1QBAknKg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On LG G7 (judyln), vbus block was kept uncontrolled.
LG V35 (judyp) doesn't have charger block wired yet in upstream, thus
nothing was done, but we know from downstream this configuration is
valid, thus enable vbus block too.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
index 6989532584251..e868cf44956b5 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
@@ -548,16 +548,23 @@ led@4 {
 
 		led@5 {
 			reg = <5>;
 			color = <LED_COLOR_ID_RED>;
 		};
 	};
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &pmi8998_wled {
 	qcom,current-limit-microamp = <20000>;
 	qcom,ovp-millivolt = <29600>;
 	qcom,switching-freq = <800>;
 	qcom,cabc;
 	status = "okay";
 };
 

-- 
2.55.0

