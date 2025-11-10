From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Nov 2025 16:37:48 +0100
Subject: [PATCH 3/3] arm64: dts: qcom: sdm845-shift-axolotl: Add ath10k
 calibration variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-sdm845-calibration-variants-v1-3-2c536ada77c2@ixit.cz>
References: <20251110-sdm845-calibration-variants-v1-0-2c536ada77c2@ixit.cz>
In-Reply-To: <20251110-sdm845-calibration-variants-v1-0-2c536ada77c2@ixit.cz>
To: Dylan Van Assche <me@dylanvanassche.be>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1017; i=david@ixit.cz;
 h=from:subject:message-id; bh=NFlBpnPvvQv4gFu7fKwiLMSzZXMqQk9CkNwxThzgmB0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEgbKmTImf9MgJ76yKNIEDZ4YVhpk2S1bgqqGc
 FiWfWc4i/CJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRIGygAKCRBgAj/E00kg
 cgT/D/9INaLxQeMVxyCU7OkDIVPZsT1+GxivrO5PLlvaSsr51iMfu0sNf4N5HsrtIo1iwWoo8kV
 kBp4ELPhF09ZofT1El1ZBB/7gh6SZsDpOaGpDuZATSbS3OlA9iJpDDW99UZAqlgS+jxWmpnaZkq
 zml1bjNM9cV1YWcUlS59+BALKrbWI4hAQUwTMeo/oqiYJOHX4/1iQRYnqIOKZCYzyx6iRMnwoVJ
 yLyY7QMKad2cruPO5VFfQTw/CC2nptTtAgu72EK4V1/L5LRaabkg0vPLE1STjEoRnv4k1oensGO
 +evcibZEqfatXs2DGCmXabxE5/XRh7hXhJZNhurWtyug63DCrbKzpsvV88YOCLQL6HgyB/Kag+X
 h1KwzKMD2MsuTbyB78dCFpC9pAJFIhZ5H7ALQmrcNcIhxAj00MZaYU57rP6tQ7cXU1n2hR+5794
 pNk4jXsozzKh+cAODdiK/j4jW3XtG4JWRNiV1kmCZXeKp3QD3XLIz0bC7hJth0Qz2glStAD9/pF
 V6KHYr/VaJUnnuASiRztedBabuNvuNctoZYwDJMhKQMiILkuh3R55bhjj+yPh2Rn7lSn9Qc/0wn
 Mtu8wS2Rj9qnf+96S5ShqbUYgqp5XTSC7R5pV7qKdBEC6iXctQQziUfMjQlf2DGPERd8xdQg+mq
 YGy5xxv5NSZly7Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Dylan Van Assche <me@dylanvanassche.be>

SDM845-based SHIFTPHONES SHIFT6mq has its own calibration files
for the WCN3990 WiFi/Bluetooth radio with the ath10k driver.
Add the calibration variant name to the DTS to reflect this to
allow using the calibration files from linux-firmware.

[David] Adjust the compatible as ath10k-calibration-variant is deprecated
Signed-off-by: Dylan Van Assche <me@dylanvanassche.be>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index ddc2b3ca3bc57..7aae5edfec26d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -740,5 +740,6 @@ &wifi {
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
+	qcom,calibration-variant = "shift_axolotl";
 	qcom,snoc-host-cap-8bit-quirk;
 };

-- 
2.51.0

