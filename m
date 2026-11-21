From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:38:02 +0100
Subject: [PATCH v3 08/12] arm64: dts: qcom: sdm845-oneplus: Enable vbus
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-8-91ba2e61a877@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=982; i=david@ixit.cz;
 h=from:subject:message-id; bh=Eep6bEgeGbDyrRVKlPckzaAdcuWR7pnxVVrNTNmBXbY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1b0pSd1UM0iCZHqOvsoxr3z/FgkiN1GZXom
 F697+iWiTmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWwAKCRBgAj/E00kg
 chYrEACT7wqVshGwHQCSqc3FSIeDpiIPp9C2PKf7TgNYhC8h8P9ynbXYtonM3Pkl7x/mOUiQX/V
 XH7oTyEWq9zIQgt6iXE6gjXmofn8Q0mS/6hp5bm6Pj5BuPPKcIxCLbu3uUMY2SYLGu/iQunc5G5
 9HSP3mDYCAlZwBUOIevgR3PU5XsEyz3Wb619XzTohZg0ADphRHzDV+C9G7mQ2mvgsmGYiEg8i0p
 b61k0mLWbgvUgepOubQMeTmZO8uEg1BkcY+MjDnFBAscuky8nXAtqAPn95XZWtTHMyUCa67mKUj
 IhJhMYdq73AyDXP8mCmaczDab6SJxtqkNDEqydEhSfNBDhrT+EK3mGIKf1Ol2O3VAwu2zG2H84u
 XYD2U42DH5OYNy3McpflODSIHx1L7USz2laVKUFJpvhEFuHMjEzWqv1XW9xQJzizE/TUDSwNhYX
 VBLwz024Cd2EZu9YzXka1tdhfqj+yXOkBA8iIIzm6/DRvSFpf7pnde9nGu4t1oqmPaimZy7+9Ev
 egrNpKd1hCFhc7JNeQX2G+Alqom0qH3hzq5krUOXybpkYkvkNVNL/tUONxnRm41EGxFzYdmdfkW
 YZl3ag3IuG/P9ocMc64AS4alFLQ5InInzgGzCXNCqnXrh01GwEpVyl63DRlJDy5KQqM1o2NRO+l
 zUHby47BtqnW1Uw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 VBUS regulator on OnePlus 6 and 6T.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 1df09da3c4d71..4996ce24fee36 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -660,16 +660,23 @@ led-1 {
 		color = <LED_COLOR_ID_YELLOW>;
 		led-sources = <2>;
 		led-max-microamp = <500000>;
 		flash-max-microamp = <1500000>;
 		flash-max-timeout-us = <1280000>;
 	};
 };
 
+&pmi8998_vbus {
+	regulator-min-microamp = <500000>;
+	regulator-max-microamp = <1500000>;
+
+	status = "okay";
+};
+
 &q6afedai {
 	dai@22 {
 		reg = <QUATERNARY_MI2S_RX>;
 		qcom,sd-lines = <1>;
 	};
 
 	dai@23 {
 		reg = <QUATERNARY_MI2S_TX>;

-- 
2.55.0

