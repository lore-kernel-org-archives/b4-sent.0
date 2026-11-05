From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Thu, 05 Nov 2026 13:54:10 +0300
Subject: [PATCH v8 06/11] dt-bindings: clock: qcom,a53pll: Add MSM8952
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-msm8952-initial-support-v8-6-311ae8e8f14b@mainlining.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793876100; l=1455;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=XCIEEjoD19j/AIKNwqTlsBvKPtPEgIUzUJWdLdc8miQ=;
 b=FuyTp0ZryxCxUbbN5sUnAwICtuCjnzrSqGz1rYWnJrBRAY0QIV3MR6pCxjCuhss75PaF5PkMP
 dfVIdPtvZD0DRyUrvt24f70eV179MSe+yXgyl6n9Lx4TjwxGi+O/JR9
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the a53pll found on MSM8952.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 .../devicetree/bindings/clock/qcom,a53pll.yaml     | 25 +++++++++++++---------
 1 file changed, 15 insertions(+), 10 deletions(-)

diff --git a/Documentation/devicetree/bindings/clock/qcom,a53pll.yaml b/Documentation/devicetree/bindings/clock/qcom,a53pll.yaml
index 1eec77e75a0a..4abfaa24bc71 100644
--- a/Documentation/devicetree/bindings/clock/qcom,a53pll.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,a53pll.yaml
@@ -15,16 +15,21 @@ description:
 
 properties:
   compatible:
-    enum:
-      - qcom,ipq5018-a53pll
-      - qcom,ipq5210-a53pll
-      - qcom,ipq5332-a53pll
-      - qcom,ipq6018-a53pll
-      - qcom,ipq8074-a53pll
-      - qcom,ipq9574-a73pll
-      - qcom,msm8226-a7pll
-      - qcom,msm8916-a53pll
-      - qcom,msm8939-a53pll
+    oneOf:
+      - enum:
+          - qcom,ipq5018-a53pll
+          - qcom,ipq5210-a53pll
+          - qcom,ipq5332-a53pll
+          - qcom,ipq6018-a53pll
+          - qcom,ipq8074-a53pll
+          - qcom,ipq9574-a73pll
+          - qcom,msm8226-a7pll
+          - qcom,msm8916-a53pll
+          - qcom,msm8939-a53pll
+      - items:
+          - enum:
+              - qcom,msm8952-a53pll
+          - const: qcom,msm8939-a53pll
 
   reg:
     maxItems: 1

-- 
2.56.0

