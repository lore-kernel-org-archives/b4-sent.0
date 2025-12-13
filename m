From: David Heidelberg <david@ixit.cz>
Date: Sat, 13 Dec 2025 13:00:21 +0100
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-db845c: Use introduced
 platform wide cam_mclk0_default
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251213-sdm845-mclk-v1-2-197bc947d4c6@ixit.cz>
References: <20251213-sdm845-mclk-v1-0-197bc947d4c6@ixit.cz>
In-Reply-To: <20251213-sdm845-mclk-v1-0-197bc947d4c6@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1459; i=david@ixit.cz;
 h=from:subject:message-id; bh=R7wOc0/W3li22Q1J4/X9qHO1WroFHpmXK6iETy2cixs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPVVV2U1w3Lv52MNqjwbzlO3Q9Z3+2zXGDIi1b
 fZj7gY/pBuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaT1VVQAKCRBgAj/E00kg
 ciqqEACXJbHxjZ3BLIDW/tuHXpqh/j4bDcR89FPsnNqFZ7fXbJZJhZSErUwV+tn0KH88XJinS/k
 6QTw3qzim1EDuILqD4daWRbkd5kV/Fh5aHSR/EQp4OGycl7wRRmRwrFOqykdjZ1BDj62MjWVj6q
 4MNLeqa41tQUpb3ElJAm/JKn/3jK+S9PwcF8gtFNwhrKqnFmRoXptHkRmNzkUPrqJuSrXcmL7jk
 2cXLrQP4Bv5E3gDqhFEEeqsucmfFVRXlJ2DWJQnujXmSiMAhg2T7NAPTWYoaSo8QkDbDju3CQTy
 7wspl0ibtKHWX+fm0m0u8a6ss6TBqM1Ta9Fiz6EraPj6M4LHwUuAD9KbtpU1miw1hqCK5yWngyo
 rHHXIUtOkDHvxlJO14zP1g2eY8H3X9QjySHDa1RbzLfqpEtFRYc06vmXY/r2XAgD4Rgnv1d2XqV
 W0uwc53Kq9PPELEA4Q00ljmmRPrRNfRRB9rwy6+UWah8+FjOWbja6RKK9vSluj1WMYDcXmezn1M
 8IclGpllQ9BvZu7Gc7IWc2S75Aua47GyFKpDne3FlZ2rrBDnVb1IxJXRS1X+fMY8XLq+GZE5eu4
 AsXPlHa/OgCfF7ZeD3TUFWLYiQdPW/wGjuPFHk/naQX/jTZQsL9vy369S8dO1yFQwQu0pZoIcYj
 tAMG9k5VmzdvCzQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All Snapdragon 845 platform has same controls GPIOs.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-db845c-navigation-mezzanine.dtso | 2 +-
 arch/arm64/boot/dts/qcom/sdm845-db845c.dts                       | 8 --------
 2 files changed, 1 insertion(+), 9 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-db845c-navigation-mezzanine.dtso b/arch/arm64/boot/dts/qcom/sdm845-db845c-navigation-mezzanine.dtso
index dbe1911d8e470..f6c2c98970d76 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-db845c-navigation-mezzanine.dtso
+++ b/arch/arm64/boot/dts/qcom/sdm845-db845c-navigation-mezzanine.dtso
@@ -40,7 +40,7 @@ camera@10 {
 		/* CAM0_RST_N */
 		reset-gpios = <&tlmm 9 GPIO_ACTIVE_LOW>;
 		pinctrl-names = "default";
-		pinctrl-0 = <&cam0_default>;
+		pinctrl-0 = <&cam0_default &cam_mclk0_default>;
 
 		clocks = <&clock_camcc CAM_CC_MCLK0_CLK>;
 		clock-names = "xvclk";
diff --git a/arch/arm64/boot/dts/qcom/sdm845-db845c.dts b/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
index ce23f87e0316b..981d19c20fa1f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-db845c.dts
@@ -877,14 +877,6 @@ rst-pins {
 			drive-strength = <16>;
 			bias-disable;
 		};
-
-		mclk0-pins {
-			pins = "gpio13";
-			function = "cam_mclk";
-
-			drive-strength = <16>;
-			bias-disable;
-		};
 	};
 
 	cam3_default: cam3-default-state {

-- 
2.51.0

