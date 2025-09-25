From: David Heidelberg <david@ixit.cz>
Date: Thu, 25 Sep 2025 11:12:50 +0200
Subject: [PATCH 4/8] arm64: dts: qcom: sdm845-oneplus-fajita: Reflect used
 panel in compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250925-s6e3fc2x01-v1-4-9293016768f7@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=861; i=david@ixit.cz;
 h=from:subject:message-id; bh=eLKrJy3MogmhhzpVb+BH02zF400XocWMS6U/eaonSM0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo1QeRvxwxJYI6TOR7wTwyUD5kobLbzqgYHQ6Bf
 KDUTcTuVRiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaNUHkQAKCRBgAj/E00kg
 cks1EAC0dCaWnmAeauXa5CENO03e6DcEb5ymfAs7+BmwY/Eg99hTreAcR+VvwTSF4Bij8gWiRqa
 Bi+mHh+j72BSu4ATwbriE1RWPelaH9qCP8LKX25jayeI0mJ0cavNd3rtl+0CSFXCNKsHAOwYMW5
 6i3q2H6pSF2sCPwWLOeu1cp4qA8rRt869uSJ0w/xYVVVlm0FUFVZZrzWT/PzpnLP03d7QPKlPT6
 fTIL8ONvJxIDfKria6ZZd1AxJYjZYngfOAbhLUWkUruedf7MRg9tBQ4L8haHAznC01CGuOKS4PE
 tJBm6WiFCZarlTQiO/r8NTZDSRriyc73pmgSPRMIfiiOJlODWyorfRwo1ukw79gahhnWW1Ly5lM
 tLrzgmHqjMzqRvWO8OrXRtbDmVM12mDgmj1Js/FPjaGYzdhk5plEEGB/TcGKOcP9JtAFEmo235R
 pZJp1LeOKYMXhhmJedmHLp/R4lbH4YkNC1Xo6h+e5kdNeFnpHTN1KpLyxmUXKoyEzsLXXwUb4AS
 noViG4wRIaBKcBfA/YuSJ4eo+7K/O4XKhAkpQu/mMiZdnCp1upI0Rd/NLxy1K5nWJv5kF5PXMhA
 CS1MqxPSWK9yeHwmsXIpnbYSBQ7LH8PIHJcUsJ7T8Y8Dx9QrQ5F8QMlaYR0ZUdVlq+FH9xctss1
 9XK2tKJoVXsWF/g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently compatible was only reflecting DDIC used, but now it also
describe the panel itself.

Fixes: 288ef8a42612 ("arm64: dts: sdm845: add oneplus6/6t devices")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index 7e75decfda052b9639f2c0ecdac5a71196fc702f..55b3e94dd97262c765165b01b07bf7052e9ffcfb 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -32,7 +32,7 @@ battery: battery {
 &display_panel {
 	status = "okay";
 
-	compatible = "samsung,s6e3fc2x01";
+	compatible = "samsung,s6e3fc2x01-ams641rw";
 };
 
 &i2c4 {

-- 
2.51.0

