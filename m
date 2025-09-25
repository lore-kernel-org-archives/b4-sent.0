From: David Heidelberg <david@ixit.cz>
Date: Thu, 25 Sep 2025 11:12:52 +0200
Subject: [PATCH 6/8] arm64: dts: qcom: sdm845-oneplus: Document TE gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-s6e3fc2x01-v1-6-9293016768f7@ixit.cz>
References: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
In-Reply-To: <20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=796; i=david@ixit.cz;
 h=from:subject:message-id; bh=9T4Q0ww4g2eijV97RS6Xs4lqrXb5AowCRGsAQv1muHM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo1QeRSud1jtDCR8KN+IdAYvFVcE+/8OksxpI87
 BpwBz+AfBuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaNUHkQAKCRBgAj/E00kg
 cs5jEACfdMDrsJqio/HPDoeB9WaYG1RnfD2Oqf+42dbVvOHvpJgzwx4laMFz0CzI+/5IpH5HM9M
 vtn+7FDc8Eu5SBDSK/OrscrKv5N3g7IOe9AM8CzEjm8rtyhvZIzUGURaL6nuzIybo+GagiL+ImI
 b51Hj/uQIRMetYEx4DJxqAcNfpOIUdTRZbqfrHUGHCUpg4/KZ1fbkpqINYPFOO/5mWE8KOf2MeE
 De3mNtbNyqnR3rcbbxNIv1Ong2HLOyPLyFpXPKDVOf0sMjEYdB4lsx+qpKfE8gCegL7LyMKlUru
 esSSzM/oKxoC4HhA0NgCSibMY9co625wt8QCsIZHzmymjO/tb/QqePCf4YVlQWQRWyJmUVUG4/2
 uXPc7sm6OBTYu3VJXou9OYqOrD/ZnyXmRO8W44CarhZQHksbZdmN/yvW/Aq2Il76csAHjFitl4Q
 yZ6Nvtauyo6deCqXJ/6M71ZnF2CvNc853itXFqd/L69mbdCnDTvk0zQd6Ip2py/RtB71+ClYHvl
 bgX22G5DaN14KflSQQwA26Vj4IZiCkY5/Yn6hXKkjiSs9C/ou7adT3QEeRaup1cT3rOVjp+hei3
 271bCZCqOy+smfOJWQvlC3Dq8GO3UbQIrOZ0zzviJOkNimnJVrq3yXKlQvMytDawnHMDrqnQMa2
 bBxYmecIjJ6uwng==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document panel Tearing Effect (TE) GPIO line.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 7f968f90a83b869395bedd5de510ba96de3c4e94..857702919084778e93da7c49afcfa6a0489d709e 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -456,6 +456,7 @@ display_panel: panel@0 {
 		vci-supply = <&panel_vci_3v3>;
 		poc-supply = <&panel_vddi_poc_1p8>;
 
+		te-gpios = <&tlmm 30 GPIO_ACTIVE_HIGH>;
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_HIGH>;
 
 		pinctrl-names = "default";

-- 
2.51.0

