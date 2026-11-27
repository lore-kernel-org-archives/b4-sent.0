From: Paul Sajna <sajattack@postmarketos.org>
Date: Fri, 27 Nov 2026 09:51:14 -0700
Subject: [PATCH v2] arm64: dts: qcom: sdm845-lg-judyln: Drop qcom,te-source
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-judyln-panel-glitch-fix-v2-1-f47fd12a04d9@postmarketos.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7ZgORExceQ/DopQBRrFt2kIkh
 LtbuYB/937y398gchCOcCs2CLxIFGczlKcCzKjtwChdZihVWVMOPudunSx6bXnCYZJkRuzlg3S
 tSbVEF6oM5LUPnOvD/GgyjxKTC+txtNCv/e9cCAnZMFOvNLWVunsX01uHFycXzy4M0Oz7/gU/T
 Mz5xQAAAA==
X-Change-ID: 20261111-judyln-panel-glitch-fix-17610b11513c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Amir Dahan <system64fumo@tuta.io>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Paul Sajna <sajattack@postmarketos.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795798281; l=1790;
 i=sajattack@postmarketos.org; s=20250413; h=from:subject:message-id;
 bh=QD858q0abRHms4/gLi2x4dtZ1gb3zWYst2XjfprddGA=;
 b=sxi2bspfe3pgmn1yvsCZD7dg/KW1GXBqTqovrrXDwD4TaUEaJRsLWe+03yfRGCEhvqC4wRGqV
 xvx1OTKrd3yCQgynZJ82mzl1cFWVlIU5544gmif09ApNmTSdVJmHPc6
X-Developer-Key: i=sajattack@postmarketos.org; a=ed25519;
 pk=ZFE/UBqiz9Wr8b+zBL27opOjw5x5ket5JFqks/VQGeM=
X-Endpoint-Received: by B4 Relay for sajattack@postmarketos.org/20250413 with auth_id=1505
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It was introduced without proper verification, and causes
graphical glitches on the display.

The default value of mdp_vsync_p is correct.

Fixes: c6c66aa3ef33 ("arm64: dts: qcom: sdm845-lg-judyln: Add display panel")

Reviewed-by: David Heidelberg <david@ixit.cz>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Paul Sajna <sajattack@postmarketos.org>
---
Changes in v2:
- Reword commit message
- Link to v1: https://lore.kernel.org/r/20261111-judyln-panel-glitch-fix-v1-1-ecee1f0a1b30@postmarketos.org

To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Abel Vesa <abelvesa@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Amir Dahan <system64fumo@tuta.io>
To: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
To: Paul Sajna <sajattack@postmarketos.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts b/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts
index 349faa123ff1..e54e46a1a6dd 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-judyln.dts
@@ -111,7 +111,6 @@ &mdss_dsi0_phy {
 &mdss_dsi0_out {
 	data-lanes = <0 1 2 3>;
 	remote-endpoint = <&panel_in>;
-	qcom,te-source = "mdp_vsync_e";
 };
 
 &ibb {

---
base-commit: aaa2f954c21b205a0bcd0961e5b2be4e82e58455
change-id: 20261111-judyln-panel-glitch-fix-17610b11513c

Best regards,
--  
Paul Sajna <sajattack@postmarketos.org>

