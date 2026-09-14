From: Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>
Date: Mon, 14 Sep 2026 16:04:23 -0600
Subject: [PATCH v3] arm64: dts: qcom: Fix touchscreen address on Dell
 Inspiron 7441
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-dell7441-touchscreen-v3-1-062d6b93d1ea@est.una.ac.cr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42OQQ6CMBBFr0K6tqQtBcSV9zAu2mGQGiymU4iGc
 Hep7tzo8s38eX8WRhgcEjtkCws4O3Kj36DYZQx64y/IXbsxU0JVopGatzgMtdaSx3GCniAgel7
 ZSglZ6L2xFdtO7wE793hrT+cP02SvCDG5UsIaQm6D8dCn0c1QxJAWvaM4huf7oVkmwY/uWXLJ2
 7optQBT4l4ekWI+eZMbyCGw1D+rf0RqE9VdrZQGAYDlt2hd1xd8yIy3MAEAAA==
X-Change-ID: 20260914-dell7441-touchscreen-6b6201348ab6
In-Reply-To: <20260914-dell7441-touchscreen-v2-1-7f7224c0cce5@est.una.ac.cr>
References: <20260914-dell7441-touchscreen-v2-1-7f7224c0cce5@est.una.ac.cr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Val Packett <val@packett.cool>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>, 
 Laurentiu Tudor <laurentiu.tudor1@dell.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789423465; l=2783;
 i=avalon.vargas.centeno@est.una.ac.cr; s=avalon-una-20260914;
 h=from:subject:message-id; bh=v75HzOpWBajfOEjPLTpITjnQWejmIESrbq0Y0aBQQ9A=;
 b=6JsiynCVSClNZxDDovanJcVOxZuqP0EkykCbcmO6O0jomdmTCwsuoKM+iScQYWFLJ7r4XEGty
 iwFJVH5JddnB9rbu3s7O3rXeQO4qZCDZg/nLgd/ZFn+FFnoZymXm+Ju
X-Developer-Key: i=avalon.vargas.centeno@est.una.ac.cr; a=ed25519;
 pk=I7FZ301yhA9Jl2LReBEqv+9LUrd5zi397CIT2gTB6RE=
X-Endpoint-Received: by B4 Relay for avalon.vargas.centeno@est.una.ac.cr/avalon-una-20260914 with auth_id=1032
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LXST2021 touchscreen on the tested Dell Inspiron 14 Plus 7441
responds at I2C address 0x09, while the device tree specifies 0x10.
Probing the latter fails with -ENXIO and no touchscreen input device
is registered.

Use address 0x09, matching the LXST2021 configuration on the related
Dell Latitude 7455. With this address, the controller identifies as
29BD:1103 and binds to hid-multitouch.

Fixes: e7733b42111c ("arm64: dts: qcom: Add support for Dell Inspiron 7441 / Latitude 7455")
Signed-off-by: Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>
---
This replaces the earlier report-plus-diff with a patch submission.
Only one unit has been tested. I have no evidence of double-sourcing
or a working Inspiron touchscreen at 0x10; a typo remains possible.

touch input and suspend/resume. The native upstream patch has not yet
undergone a full kernel DTB build or dtbs_check.

Validation: Linux 7.2.4 plus the equivalent local DT overlay, physical
---
Changes in v3:
- Add the Fixes tag for the commit that introduced the incorrect address.
- Link to v2: https://patch.msgid.link/20260914-dell7441-touchscreen-v2-1-7f7224c0cce5@est.una.ac.cr

Changes in v2:
- Drop the testing details from the commit message as requested.
- Link to v1: https://patch.msgid.link/20260914-dell7441-touchscreen-v1-1-d79540ca5e81@est.una.ac.cr

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Laurentiu Tudor <laurentiu.tudor1@dell.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
To: Val Packett <val@packett.cool>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts b/arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts
index 75e10d97c..0cf5716cd 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts
@@ -25,9 +25,10 @@ &gpu_zap_shader {
 };
 
 &i2c8 {
-	touchscreen@10 {
+	/* LXST2021 */
+	touchscreen@9 {
 		compatible = "hid-over-i2c";
-		reg = <0x10>;
+		reg = <0x09>;
 
 		hid-descr-addr = <0x1>;
 		interrupts-extended = <&tlmm 51 IRQ_TYPE_LEVEL_LOW>;

---
base-commit: 704340f1cd0dcef829eb62f5b48ae95a2ce17bdf
change-id: 20260914-dell7441-touchscreen-6b6201348ab6

Best regards,
--  
Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>

