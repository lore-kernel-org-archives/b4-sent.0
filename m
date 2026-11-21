From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:38:03 +0100
Subject: [PATCH v3 09/12] arm64: dts: qcom: sdm845-shift-axolotl: Enable
 vbus support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-9-91ba2e61a877@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=957; i=david@ixit.cz;
 h=from:subject:message-id; bh=2lgBmUBK0MaeAv9Oy1xMjAHeZ/2PGxZmYEJJF355C18=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1b4BJsvRNFa2l8cfLZ4YY1SPxbJVnWYZzzH
 KQxHnJ/Ju+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWwAKCRBgAj/E00kg
 cihpD/4vpQ/Ai/GFX6wI1ydBxLKNxq2GZDM14X30jXravqIIUy98BJWgXqgDjpevL58+1ZDPS/m
 qgwh71ivI4xlNmuTy7ajuK5Wnf6xXT3IT0uyfhoO2/+7aWal5goKbuxvOyms5/xP6TpgDNwDAwm
 6TmH/SJDpGksTNi1o8k3YY+PQPrHu26yR4YYtzYGCh/hJm19Re0vC6HPKKxdqaF1jwsPZ5RCvbv
 E4MN6eHnhAPpERMQz3pYk29PeeFTFJ+RABz7ATKl1RraI0RmeX06tj7mdYhuHSxgtTdTiJMgrFw
 rWZVTJPlKiBMX4Jz5lh21u4lTB/dAWv9VKGyCOBqGTiY/XQkgdqEfLV+nCbVxTgdbL2ucmj3WxZ
 fUDi/53lcCcRNxl/CGEwAultmZcbgHym+XpM5X/z3xVTLa22lPwj0pbPBfq26B495LKZ9VYW7fi
 OIVVgMGpQlP2amkMLGvhOsNLqTatTvyqOTwQjCfMLSaa6pOxids2xcSqE00GSheN717P/RIlj9A
 7FYRRjsPE+gVHzt6ag9KvmGId1HhltU7sIMoyMg8JSs7I6yncaQ+WJoiDRWk5uKB2/Feg0spHc9
 khoYYy/RDknoyqAMao2S2GPIdT3wghftMvIkiL6m5cDS0t1v8jbXwG2BymMPuyoL9DaMmhXnFJd
 gELXppbGgCiXiZg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 VBUS regulator on SHIFT 6MQ.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 1b0eaeafbd517..124717214edd6 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -654,16 +654,23 @@ led-1 {
 		color = <LED_COLOR_ID_YELLOW>;
 		led-sources = <2>;
 		led-max-microamp = <100000>;
 		flash-max-microamp = <1100000>;
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
 &qup_uart9_rx {
 	drive-strength = <2>;
 	bias-pull-up;
 };
 
 &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;

-- 
2.55.0

