From: Ivan Verbovoy <ivanverbovoy@gmail.com>
Date: Tue, 03 Nov 2026 21:27:19 +0200
Subject: [PATCH] arm64: dts: qcom: sm8150-microsoft-surface-duo: fix da7280
 pinctrl state name
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-a1-duo-da7280-pinctrl-v1-1-be1a6dd10f20@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtoO9Dqq4iHLIkuQ7rRbmMw9
 u5WPX6H/9+haDYtcGt2yLpasTFV+FMD3FN6KZpUQ3Dh7L1rkTzKMqLQJUSHkyWe8xs7FSEmjuE
 aobZT1qdtv+/98XdZukF5/s7gOD5L1h5JeQAAAA==
X-Change-ID: 20261103-a1-duo-da7280-pinctrl-beddacac8298
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ivan Verbovoy <ivanverbovoy@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793734043; l=1561;
 i=ivanverbovoy@gmail.com; s=20261103; h=from:subject:message-id;
 bh=0js5pdnbTdQyzcVH7Eyw2YpiHysbE+V0Y8mJj4fF7JI=;
 b=RiH3K/R1JRzpBkJIo7DjuAXmYGNE3FhsOK/XAyLQC8ue2NxiLReGgvu9T8ZGQZzvu7oChjSQ0
 EA4YRzzS1TcCCz0Lo18EYHNHy2CBbuZCiYS404fLAJtR+ayJpbzN+4M
X-Developer-Key: i=ivanverbovoy@gmail.com; a=ed25519;
 pk=0AchqTH1hJFToIUeFfQRlVzzuaWQDs4e75SxT2y3s8c=
X-Endpoint-Received: by B4 Relay for ivanverbovoy@gmail.com/20261103 with auth_id=1396
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pinctrl core applies a device's "default" state by itself and the
da7280 driver requests no state of its own, so the state named
"da7280_default" is never selected: gpio42 stays as the firmware left it
and its pull-up is not applied. The interrupt line is open-drain and
level-low; after a suspend/resume cycle it stays low and the threaded
handler runs continuously (about 2900 times a second) with no event in
the chip, which slows the whole system down.

Name the state "default" so it is applied at probe.

Fixes: d1f781db47a8 ("arm64: dts: qcom: add initial device-tree for Microsoft Surface Duo")
Signed-off-by: Ivan Verbovoy <ivanverbovoy@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8150-microsoft-surface-duo.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8150-microsoft-surface-duo.dts b/arch/arm64/boot/dts/qcom/sm8150-microsoft-surface-duo.dts
index f37e11bde067..4078a7521a2e 100644
--- a/arch/arm64/boot/dts/qcom/sm8150-microsoft-surface-duo.dts
+++ b/arch/arm64/boot/dts/qcom/sm8150-microsoft-surface-duo.dts
@@ -372,7 +372,7 @@ da7280@4a {
 		compatible = "dlg,da7280";
 		reg = <0x4a>;
 		interrupts-extended = <&tlmm 42 IRQ_TYPE_LEVEL_LOW>;
-		pinctrl-names = "da7280_default";
+		pinctrl-names = "default";
 		pinctrl-0 = <&da7280_intr_default>;
 
 		dlg,actuator-type = "LRA";

---
base-commit: d6bcfc94eb4da6e089c5473970cd96727292fd97
change-id: 20261103-a1-duo-da7280-pinctrl-beddacac8298

Best regards,
--  
Ivan Verbovoy <ivanverbovoy@gmail.com>

