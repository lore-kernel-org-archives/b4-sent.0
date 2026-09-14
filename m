From: Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>
Date: Mon, 14 Sep 2026 08:19:12 -0600
Subject: [PATCH v2] arm64: dts: qcom: Fix touchscreen address on Dell
 Inspiron 7441
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-dell7441-touchscreen-v2-1-7f7224c0cce5@est.una.ac.cr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOQQ6CMBBFr0K6tqStpaAr72FYTMsoNVhMpxAN4
 e5SPIDL92fm/VkYYfRI7FwsLOLsyY9hA3UomOsh3JH7bmOmhDLiJDXvcBhqrSVP4+R6chExcGO
 NEvKoG7CGbaeviDf/3rXX9sc02Qe6lF15wwIhtxGC63P0BEoY86D3lMb42R+aZRb86Z4ll7yrT
 5UWDips5AUplVOAElzpImvXdf0CiCOKQecAAAA=
X-Change-ID: 20260914-dell7441-touchscreen-6b6201348ab6
In-Reply-To: <20260914-dell7441-touchscreen-v1-1-d79540ca5e81@est.una.ac.cr>
References: <20260914-dell7441-touchscreen-v1-1-d79540ca5e81@est.una.ac.cr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789395556; l=2302;
 i=avalon.vargas.centeno@est.una.ac.cr; s=avalon-una-20260914;
 h=from:subject:message-id; bh=6gBsV7jPIMZCPp+JlhmXPksh2uvU1i6L1e9XqSDCAiw=;
 b=ZYH8yQrfacLkBtsncjtGdW8vXgGgPM/evxGnTyhkeXzbHgAKY/9UTIj1I0W1UN3ejqHJIVqHR
 F8PySNTN4CFBhYR11IRgw1vhN6xRakWDEwqcTGHwkKCQlkME7BDLwbf
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

Signed-off-by: Avalon Vargas <avalon.vargas.centeno@est.una.ac.cr>
---
This replaces the earlier report-plus-diff with a patch submission.
Only one unit has been tested. I have no evidence of double-sourcing
or a working Inspiron touchscreen at 0x10; a typo remains possible.

touch input and suspend/resume. The native upstream patch has not yet
undergone a full kernel DTB build or dtbs_check.

Validation: Linux 7.2.4 plus the equivalent local DT overlay, physical
---
Changes in v2:
- Drop the testing details from the commit message as requested.
- Link to v1: https://patch.msgid.link/20260914-dell7441-touchscreen-v1-1-d79540ca5e81@est.una.ac.cr

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
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

