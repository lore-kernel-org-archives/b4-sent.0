From: Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>
Date: Mon, 14 Sep 2026 07:30:47 -0600
Subject: [PATCH] arm64: dts: qcom: Fix touchscreen address on Dell Inspiron
 7441
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-dell7441-touchscreen-v1-1-d79540ca5e81@est.una.ac.cr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMyw7CIBBFf6WZtSSABB+/YlwAHWVMpWaGGpOm/
 y7o8tzcc1YQZEKB87AC45uE5tLA7AZIOZQ7Khobg9XW65NxasRpOjhnVJ2XlCUxYlE+eqvN3h1
 D9NDUF+ONPr/s5fpnWeIDU+2t/ohBUEUOJeU+PYNUZNi2Lxvirp6RAAAA
X-Change-ID: 20260914-dell7441-touchscreen-6b6201348ab6
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Val Packett <val@packett.cool>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789392660; l=1937;
 i=avalon.vargas.centeno@est.una.ac.cr; s=avalon-una-20260914;
 h=from:subject:message-id; bh=cWKOXfSe8ZMCWag3Rxp781xh1Hgee6YPOPUmg88AEUg=;
 b=FayQ/FIpndcg5F9U82KQTUWBFChd9LE0wC09Rwqx5L/LbJmEocy1yRMpLDy6XxVvXCd7RqZO/
 e4kAxKsH227CfRIje3fiLIkNHHlW5RPRbbXXgsMdHh8llOfoxy/alhI
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
29BD:1103 and binds to hid-multitouch. Touch input and suspend/resume
have been verified on the affected Inspiron using Linux 7.2.4 with
the equivalent device-tree overlay.

Signed-off-by: Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>
---
This replaces the earlier report-plus-diff with a patch submission.
Only one unit has been tested. I have no evidence of double-sourcing
or a working Inspiron touchscreen at 0x10; a typo remains possible.

touch input and suspend/resume. The native upstream patch has not yet
undergone a full kernel DTB build or dtbs_check.

Validation: Linux 7.2.4 plus the equivalent local DT overlay, physical
---
 arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts b/arch/arm64/boot/dts/qcom/x1e80100-dell-inspiron-14-plus-7441.dts
index 75e10d9..0cf5716 100644
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

