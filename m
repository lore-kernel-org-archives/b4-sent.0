From: Aaron Kling <webgeek1234@gmail.com>
Date: Sat, 07 Feb 2026 19:16:03 -0600
Subject: [PATCH v2] arm64: dts: qcom: sm8550: Fix DTBO boot failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260207-sm8550-abl-dtbo-v2-1-83afaa6f3ce9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XNQQ6DIBCF4auYWZcGEAl21Xs0LkBQJxExYEwbw
 92LJl11+b1k/jkguYguwaM6ILodE4algN8q6Ce9jI6gLQZOuaSMK5K8ahpKtJmJ3UwgreRKyVo
 MlFooV2t0A76v4qsrnjBtIX6uBzs711+r/WvtjJzqdW0cE5SL5+g1zvc+eOhyzl/e1kFcrgAAA
 A==
X-Change-ID: 20260128-sm8550-abl-dtbo-96288634f00d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kumar Sharma <quic_vksharma@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Pavan Kondeti <pavan.kondeti@oss.qualcomm.com>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770513395; l=1988;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=MSt9cy30dkO5MvzrubSqKSonGMw3uBt52RdVxTWvKPc=;
 b=G4vENHVOwE6gA6R07OA3RFFApGCvnwOs8k3qr6VXVEl9LdUXpxPa+DGe/E/teL/EeesV1prVL
 1RTdbO0bnoJBREC3HJW7ea+EUP5is4atVfSSAAPaRoW0JtF/JKnxmfU
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Pavan Kondeti <pavan.kondeti@oss.qualcomm.com>

ABL requires certain things in the base dtb to apply a dtbo. Namely:

* A label named qcom_tzlog must exist, but doesn't have to contain any
  specific properties
* The timer node must have a label named arch_timer

This aligns the sm8550 soc dtsi with those requirements. Without these
in the base dtb, when ABL attempts to apply any dtbo, it will fail to
the bootloader menu.

Co-authored-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
With a current mainline sm8550 base dtb, ABL will fail to apply any dtbo
and fail back to the bootloader menu. There are two changes needed:

* Add a label named qcom_tzlog
* Add a label named arch_timer to the timer node
---
Changes in v2:
- Drop tz log changes
- Add tz log label to a generic node
- Link to v1: https://lore.kernel.org/r/20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index e3f93f4f412ded9583a6bc9215185a0daf5f1b57..04ea1a4a015aa5a4fd615e068b6f18b7c336607c 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -32,7 +32,8 @@ / {
 	#address-cells = <2>;
 	#size-cells = <2>;
 
-	chosen { };
+	// This label is required by ABL to apply a dtbo
+	qcom_tzlog: chosen { };
 
 	clocks {
 		xo_board: xo-board {
@@ -6756,7 +6757,8 @@ trip-point2 {
 		};
 	};
 
-	timer {
+	// This label is required by ABL to apply a dtbo
+	arch_timer: timer {
 		compatible = "arm,armv8-timer";
 		interrupts = <GIC_PPI 13 (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW) 0>,
 			     <GIC_PPI 14 (GIC_CPU_MASK_SIMPLE(8) | IRQ_TYPE_LEVEL_LOW) 0>,

---
base-commit: 3f24e4edcd1b8981c6b448ea2680726dedd87279
change-id: 20260128-sm8550-abl-dtbo-96288634f00d

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

