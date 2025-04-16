From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Wed, 16 Apr 2025 11:13:35 +0200
Subject: [PATCH] arm64: dts: qcom: x1e80100-hp-omnibook-x14: Remove invalid
 bt-en-sleep node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-fix-omnibook-dts-v1-1-2409220a7c6f@canonical.com>
X-B4-Tracking: v=1; b=H4sIAL50/2cC/x2MQQqAIBAAvyJ7bkHFpPpKdLDaaok0NCII/550H
 JiZFxJFpgSdeCHSzYmDL6AqAdPm/ErIc2HQUtfSKIsLPxgOz2MIO85XwtZM2rXamsbWULIzUnH
 +ZT/k/AFPOfxUYgAAAA==
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1564;
 i=juerg.haefliger@canonical.com; h=from:subject:message-id;
 bh=ghuP4WA9I34RJPerKbhGPvLIaYpn+6TGHXDyTAaAGtI=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBn/3TQMO+HEhY/5tu1QCR/ulQ3RWR1SmWv5FAFy
 8RdKsTNzJyJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCZ/900AAKCRAP04sJC6ZC
 tyZnEACvj5pe+h/WGp0qT12bYG9YMSWrjbdU8Jx1AGK1ZbbVmyqpDlE15/R1zvZLskuliMowKv2
 Zv76nCWn7UML5e0miuYKwe+dhyreHi3ufBpuMdJAKkBSYyMQhpr96dg0oVnQGJs1j8mDiAY/Ujs
 uv6+TbqiSqrB0xumlfj9UdICUsquVcdL/t2VtgmHpD/Jg/DLXI00wFJlbmpTDs2ltyDaHffqMTv
 LYErbOQjHaQmfwhwAzd4e/2rX/x6YWOyfiv4UbTVfXMjEOVsdwPXM9dZPohirqzmmjfWCU36cv9
 AfXkvor0OyyvPcySMtwmWy2HHElwTENgc8LMNNDZk+AcpQTGQ2Pf8FRqTzTe1HkXo5qZ3pbLekA
 2O+PE0l6Ut/Ugb2gDGlWRTdKF2YNXVDkq0wmC2OYvkDxy4/Vm1okVQJsczAJ4A7O28Iw1c2tybu
 Ld8R2nFT4zdryKb0wNRZdUJcwvNR9POnDXnNo5oX4GWhri4YlVMKcaOL2e2PHFpbRsVrV4uedet
 hseWMNQIbz0w+d/sQ1ZtNGeqx8Utb71G6fU1QvMCqD9v1VxLctCa5Fdo3xAo58qj3phDVwz42L5
 0rN9HVNcBYCoHnkl7agsKX6jX6qs1FTwukrSVBbYivX9fYP5fB7B7Tm3jAjvU4zNwlUgYbIR12A
 KIG9ELv5CIUh/5g==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/default with auth_id=381
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the invalid bt-en-sleep node. Not sure how it came into existence
but it seems the functionality is covered by the wcn-wlan-bt-en-state node:

	wcn_wlan_bt_en: wcn-wlan-bt-en-state {
		pins = "gpio116", "gpio117";
		function = "gpio";
		drive-strength = <2>;
		bias-disable;
	};

This fixes the following warning:

arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dtb: pinctrl@f100000: Unevaluated properties are not allowed ('bt-en-sleep' was unexpected)
        from schema $id: http://devicetree.org/schemas/pinctrl/qcom,x1e80100-tlmm.yaml#

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts | 8 --------
 1 file changed, 8 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
index cd860a246c45..2203abef36b5 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
@@ -1425,14 +1425,6 @@ &tlmm {
 			       <72 2>, /* Secure EC I2C connection (?) */
 			       <238 1>; /* UFS Reset */
 
-	bt_en_default: bt-en-sleep {
-		pins = "gpio116";
-		function = "gpio";
-		output-low;
-		bias-disable;
-		drive-strength = <16>;
-	};
-
 	edp_reg_en: edp-reg-en-state {
 		pins = "gpio70";
 		function = "gpio";

---
base-commit: 1a1d569a75f3ab2923cb62daf356d102e4df2b86
change-id: 20250416-fix-omnibook-dts-94c2a9264865

Best regards,
-- 
Juerg Haefliger <juerg.haefliger@canonical.com>

