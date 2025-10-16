From: David Heidelberg <david@ixit.cz>
Date: Thu, 16 Oct 2025 18:16:58 +0200
Subject: [PATCH v3 3/8] arm64: dts: qcom: sdm845-oneplus-fajita: Compatible
 describing both DDIC and panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-s6e3fc2x01-v3-3-ce0f3566b903@ixit.cz>
References: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
In-Reply-To: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=860; i=david@ixit.cz;
 h=from:subject:message-id; bh=Mdaar2hgWJbOqSL6WtOcpPiawiVPmyRpa3cF3G5hBoI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8Rp57dX7ERbtZtzUrmaWGhO+aGlrVwvoenRp9
 A1HmNyxuGiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPEaeQAKCRBgAj/E00kg
 cjYwD/43O/OAxwTC9/HG211kyEcuYIlgg7oCSb3+0B/WhuGKVrsmUHI6cJ+RN600JacTLU5NbeO
 t+w3U+GuuYRc9Lp22XmFaOBDtoUaawhILNdVZ6LBD0bYoVFGP6MB84FvQBesQcutUpFE4NuBXPG
 d6dw/Ke0SvQYQKuKmwn5+NoZgrdyQBL3oyIhM1ZPSCJrg/bzofPcd6zT50p7+2SDIgC0BcRQDT3
 RVz/+smDnF520VbKvFxxgdd6kzzCYtEox52FGm41l+b9q9erplPpLHxJJvZys2z5aN/bRafxkNQ
 CUcHiZ20SS1Y6AFi8Dl+FpS+Tm6slPbtrr93I5gy98z7Hyfcra6HHTV3GZIXUsq8AL74NcJVbdB
 bXqbIU/B3mZ9TW5X9mkje9i8D20bwWK1XuHdqLyUqA65pOOxZgop74qAd3g8RsMEeA01KEqTv91
 UIQ3ul1Tctg4FkiiWzqUSAiqWVywdy2Sb5JCnAfhEOYjWmbVBpDHL4/wiqapiK7xX3R7U96lOx7
 HWHC9oQ8ic4o+6x8no/uIfE2UulfJCUbxK6cPOeYSiLqNr9sINupQ8o22sn97Fdiykm3niS2ZOt
 Bchyh99+Jv3itFzzcV0kMbgLpyTTvmsSP3/4CjipaDGezxBEE1jehByVFlSsYn5ktvRgHX2PF3d
 PE42kB15glEDjig==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Compatible should precisely describe the hardware used.
Original compatible describing only the DDIC used, but omit describing
the panel used (Samsung AMS641RW), which we have no way to detect.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index 7e75decfda052..d6cd873aef0de 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -32,7 +32,7 @@ battery: battery {
 &display_panel {
 	status = "okay";
 
-	compatible = "samsung,s6e3fc2x01";
+	compatible = "samsung,s6e3fc2x01-ams641rw", "samsung,s6e3fc2x01";
 };
 
 &i2c4 {

-- 
2.51.0

