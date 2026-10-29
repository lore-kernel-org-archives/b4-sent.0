From: Vladlen Grachev <webholt@gmail.com>
Date: Thu, 29 Oct 2026 18:12:17 +0000
Subject: [PATCH] arm64: dts: qcom: msm8996-oneplus-common: Drop LVS2
 voltage constraints
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-op3t-lvs2-fix-v1-1-42ca9d992c20@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7bsHMIvtKdAhbayFSNCQI/550n
 IGZFxJFpgSTeCFS5sT+qtA2AuyxXjshb5VBSTW0Uhn0obvxzEmh4we1tqORvaVOO6hNiFT1/5u
 XUj6vgMRpXwAAAA==
X-Change-ID: 20261029-op3t-lvs2-fix-44c8905ce34f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Vladlen Grachev <webholt@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793297541; l=2127;
 i=webholt@gmail.com; s=20261029; h=from:subject:message-id;
 bh=HebHQtTCozbcTjBAD2cRWkL8+SEDKdyhDnbeViDQK38=;
 b=lRJ+qH7Rt37iPLxVprrqAsVq6NOKR62bVoWBe6x0IUwCAw+I7n+az0QKhhiMKSpk3JylSNISV
 ywt0RvU0gRpBXfNeZ2dkJoqiJ32HYRIyFz25kCtcPCOvcOlCF1H9zNU
X-Developer-Key: i=webholt@gmail.com; a=ed25519;
 pk=8kq937AiLEx3pRQ9J+BUXm28cQqT4RyMTPY5dyb04kc=
X-Endpoint-Received: by B4 Relay for webholt@gmail.com/20261029 with auth_id=1356
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 27880745470a ("arm64: dts: qcom: msm8996-oneplus: Add SLPI
VDD_PX"), OnePlus 3T no longer boots: the PM8994 RPM regulator device
fails to probe, so UFS, USB and the display never come up and the phone
hangs on the bootloader splash screen:

  lvs2: failed to get the current voltage: -EINVAL
  qcom_rpm_smd_regulator remoteproc:glink-edge:rpm-requests:regulators:
    lvs2: devm_regulator_register() failed, ret=-22
  qcom_rpm_smd_regulator remoteproc:glink-edge:rpm-requests:regulators:
    probe with driver qcom_rpm_smd_regulator failed with error -22

The switch LVS2 cannot report its voltage, so the regulator core asks
its input supply, vdd_lvs1_2, which is not described on these
boards. Checking the 1.8 V constraint then fails with -EINVAL, and the
RPM regulator driver aborts the probe of all PM8994 regulators.

Drop the constraints, like apq8096-db820c, which describes LVS1/LVS2
without them. Keep the node, so that the SLPI still gets its px-supply.

Describing vdd_lvs1_2-supply as S4, as done on other MSM8996 boards,
would also work, but it would only serve the constraint, which has
nothing to enforce on a switch.

Tested on OnePlus 3T with the msm8996-mainline kernel based on v6.19.5.

Fixes: 27880745470a ("arm64: dts: qcom: msm8996-oneplus: Add SLPI VDD_PX")
Cc: stable@vger.kernel.org
Signed-off-by: Vladlen Grachev <webholt@gmail.com>
---
 arch/arm64/boot/dts/qcom/msm8996-oneplus-common.dtsi | 2 --
 1 file changed, 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/msm8996-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/msm8996-oneplus-common.dtsi
index 7a3f8afae..98fc45dc8 100644
--- a/arch/arm64/boot/dts/qcom/msm8996-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/msm8996-oneplus-common.dtsi
@@ -497,8 +497,6 @@ vreg_l32a_1p8: l32 {
 		};
 
 		vreg_lvs2a: lvs2 {
-			regulator-min-microvolt = <1800000>;
-			regulator-max-microvolt = <1800000>;
 		};
 	};
 };

---
base-commit: f5672a3dff0291d6a45eb0c258b9d2baeb4dc577
change-id: 20261029-op3t-lvs2-fix-44c8905ce34f

Best regards,
-- 
Vladlen Grachev <webholt@gmail.com>

