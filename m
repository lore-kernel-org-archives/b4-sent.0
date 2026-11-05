From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Thu, 05 Nov 2026 13:54:12 +0300
Subject: [PATCH v8 08/11] dt-bindings: remoteproc: qcom: adsp: Add MSM8952
 ADSP compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-msm8952-initial-support-v8-8-311ae8e8f14b@mainlining.org>
References: <20261105-msm8952-initial-support-v8-0-311ae8e8f14b@mainlining.org>
In-Reply-To: <20261105-msm8952-initial-support-v8-0-311ae8e8f14b@mainlining.org>
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Rajendra Nayak <quic_rjendra@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Krishna Manikandan <quic_mkrishn@quicinc.com>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: David Heidelberg <david@ixit.cz>, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 linux-watchdog@vger.kernel.org, linux-clk@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, freedreno@lists.freedesktop.org, 
 linux-remoteproc@vger.kernel.org, linux-input@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793876100; l=1719;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=TdJtPJWcgCTApekSG/YSFXMQlTXs1iJDxy72QBeRJ4I=;
 b=T86QTCcFsFyUBp42pyRmNcskgrmpmOK8QjvuxWKygJkNXfzpP85MKuEolyU9Mwj3BXjGiAYcY
 tUmSQ1KD4kKDOykvEwD+rFHRKCyno1XbyObG/bYZOAgz7EEuwaX5hP/
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the ADSP remoteproc found on the MSM8952.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 .../devicetree/bindings/remoteproc/qcom,adsp.yaml  | 31 +++++++++++++---------
 1 file changed, 18 insertions(+), 13 deletions(-)

diff --git a/Documentation/devicetree/bindings/remoteproc/qcom,adsp.yaml b/Documentation/devicetree/bindings/remoteproc/qcom,adsp.yaml
index 7e8ecae8e6cb..1e4650aafa82 100644
--- a/Documentation/devicetree/bindings/remoteproc/qcom,adsp.yaml
+++ b/Documentation/devicetree/bindings/remoteproc/qcom,adsp.yaml
@@ -15,19 +15,24 @@ description:
 
 properties:
   compatible:
-    enum:
-      - qcom,msm8226-adsp-pil
-      - qcom,msm8953-adsp-pil
-      - qcom,msm8974-adsp-pil
-      - qcom,msm8996-adsp-pil
-      - qcom,msm8996-slpi-pil
-      - qcom,msm8998-adsp-pas
-      - qcom,msm8998-slpi-pas
-      - qcom,sdm660-adsp-pas
-      - qcom,sdm660-cdsp-pas
-      - qcom,sdm845-adsp-pas
-      - qcom,sdm845-cdsp-pas
-      - qcom,sdm845-slpi-pas
+    oneOf:
+      - enum:
+          - qcom,msm8226-adsp-pil
+          - qcom,msm8953-adsp-pil
+          - qcom,msm8974-adsp-pil
+          - qcom,msm8996-adsp-pil
+          - qcom,msm8996-slpi-pil
+          - qcom,msm8998-adsp-pas
+          - qcom,msm8998-slpi-pas
+          - qcom,sdm660-adsp-pas
+          - qcom,sdm660-cdsp-pas
+          - qcom,sdm845-adsp-pas
+          - qcom,sdm845-cdsp-pas
+          - qcom,sdm845-slpi-pas
+      - items:
+          - enum:
+              - qcom,msm8952-adsp-pil
+          - const: qcom,msm8996-adsp-pil
 
   reg:
     maxItems: 1

-- 
2.56.0

