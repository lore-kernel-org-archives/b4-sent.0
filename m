From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Sat, 12 Sep 2026 11:39:25 +0300
Subject: [PATCH RFC 16/20] dt-bindings: thermal: tsens: Add MSM8952
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260912-msm8952-initial-support-v1-16-0e742578b524@mainlining.org>
References: <20260912-msm8952-initial-support-v1-0-0e742578b524@mainlining.org>
In-Reply-To: <20260912-msm8952-initial-support-v1-0-0e742578b524@mainlining.org>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Ulf Hansson <ulfh@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Lee Jones <lee@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Robert Marko <robimarko@gmail.com>, Guru Das Srinagesh <linux@gurudas.dev>, 
 Amit Kucheria <amitk@kernel.org>, Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: David Heidelberg <david@ixit.cz>, Dang Huynh <danct12@riseup.net>, 
 phone-devel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 iommu@lists.linux.dev, mfd@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 linux-pm@vger.kernel.org, linux-input@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789202354; l=797;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=SHQrlXrOKfClSSRN67nbliq/vzHPWzLada9e+lrsFjk=;
 b=6PA6NmEgUQ0+HVxnxKIS1Rps1nE6jluEZqKw0B9t6fZK/k8tUGG/aqh5ETyWK0HE8R1OS6mTS
 vmKKlI3zzAJAx5HjDMNyrJM829WeCzGX14kOv3rZ0gjr7eQCdkhmj/G
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string for tsens block found in MSM8952.

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 Documentation/devicetree/bindings/thermal/qcom-tsens.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
index 5a8f7673e730..c78074fbcecf 100644
--- a/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
+++ b/Documentation/devicetree/bindings/thermal/qcom-tsens.yaml
@@ -46,6 +46,7 @@ properties:
         items:
           - enum:
               - qcom,msm8937-tsens
+              - qcom,msm8952-tsens
               - qcom,msm8956-tsens
               - qcom,msm8976-tsens
               - qcom,qcs404-tsens

-- 
2.54.0

