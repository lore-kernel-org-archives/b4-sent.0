From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Tue, 13 Oct 2026 16:40:56 +0200
Subject: [PATCH 1/3] dt-bindings: arm: qcom: Document HP EliteBook 6 G1q
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-add-elitebook-6-dts-v1-1-f22e67fc7f9d@canonical.com>
References: <20261013-add-elitebook-6-dts-v1-0-f22e67fc7f9d@canonical.com>
In-Reply-To: <20261013-add-elitebook-6-dts-v1-0-f22e67fc7f9d@canonical.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=906;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=DoiEVJtPjXSpbE/tu9R+shKoxBbwNwzwDSKezr3bIi0=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqzkMKlMLDVRn5psGzGZjctopgbBMo6MXXyPxZe
 hAWFalBQeWJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCas5DCgAKCRAP04sJC6ZC
 t6coEACIMdjKROjHf3W4UyMSYrMVLtsh0gRq//NksYoV81dZaQs7OKv6ePUzvBkmcaR0WjGCK5V
 RscZ8Mj1fn0H4bzyEPpSDb22I1BihlheSIOrarWLqY/6QLFl2cK8Yjt41y3s3mMPee85yus6dUt
 p/Hma+WF1uLEwCWi5WyrMfHGXKCyOvmbgkSFYh16hX36L5iXsmdhPGbZJxKihXMlMuRnCbuxPPm
 SMZSIQdDd1+wSraWx9qzIsgSjGnseLExsm5SJ6v3j19AGl7ZZP/Bc/WrBgpZnhg9KJ+vKmP5y+O
 NSAWwt6UFXXIBbOmxKS0yYLp8Q4lXMKUXoHwpCvSJQGa5dPF/cBT6OSHhE0idNjhKmVIffXdMxH
 ZsTjG39orXAVGrl382QAaS4RviIaUFmJPSEE54VhW2Ai9ZVg01KyvTDCqkhrTkkQbDE/cZZ4uI2
 hswlySlLBS1rXtv8VEt/bsHRhWdetGeblBQ7f3esK4KCJaic9UxkXx65pgzaP8/7aFiA/e2CsyF
 UP6+UMNoK5f+122L1hyQWXM9W+6aAHh2wPmt4zqia/GYx1VltqY7CsszuSyVcOAlzURL4ONcmj/
 NfwU84QuevM9xiUhU9KCtfWdWzt2LiNfOsEmoKUBTMYkk86Y008yflGykSwPJB4Vi8QGMkRoEaP
 0dhnvJByuLdZP6g==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible for the HP EliteBook 6 G1q 14 inch Notebook Next Gen AI
PC, based on the Qualcomm Snapdragon X1P42100 SoC.

PDF link: https://www8.hp.com/h20195/v2/GetDocument.aspx?docname=c09121784

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 121ca557ce1e..1b59f4379859 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1307,6 +1307,7 @@ properties:
       - items:
           - enum:
               - asus,vivobook-s15-x1p4
+              - hp,elitebook-6-g1q
               - hp,omnibook-x14-fe1
               - lenovo,thinkbook-16
               - qcom,x1p42100-crd

-- 
2.53.0

