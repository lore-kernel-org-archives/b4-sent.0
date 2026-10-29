From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Date: Fri, 30 Oct 2026 00:02:41 +0300
Subject: [PATCH v7 10/11] dt-bindings: input: touchscreen: goodix: Add
 binding for GT970
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-msm8952-initial-support-v7-10-ad748ace375d@mainlining.org>
References: <20261030-msm8952-initial-support-v7-0-ad748ace375d@mainlining.org>
In-Reply-To: <20261030-msm8952-initial-support-v7-0-ad748ace375d@mainlining.org>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793307755; l=1656;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=WcI6NF2jH7/1jsgO/qq/6GfopHH27DV/LBlXLYlg2yo=;
 b=KaVq6JMZuo3i7wkTjbLJsHd9Jmfne5+q+ucL4Yn9K7uwr8fdG/0pQ6H8NdBv0fDg2nySA2G7s
 XCRYwH3A72GAEr18ksMnVvsYSFPJtptrjY7nrZRMU5r8xHer6DbMIDY
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GT970 works with GT911 driver, document it to be
used with GT911 compatible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
 .../bindings/input/touchscreen/goodix.yaml         | 35 ++++++++++++----------
 1 file changed, 20 insertions(+), 15 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml b/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml
index a26a54d63a1c..4be2c137abd7 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/goodix.yaml
@@ -14,21 +14,26 @@ allOf:
 
 properties:
   compatible:
-    enum:
-      - goodix,gt1151
-      - goodix,gt1158
-      - goodix,gt5663
-      - goodix,gt5688
-      - goodix,gt911
-      - goodix,gt9110
-      - goodix,gt912
-      - goodix,gt9147
-      - goodix,gt917s
-      - goodix,gt927
-      - goodix,gt9271
-      - goodix,gt928
-      - goodix,gt9286
-      - goodix,gt967
+    oneOf:
+      - enum:
+          - goodix,gt1151
+          - goodix,gt1158
+          - goodix,gt5663
+          - goodix,gt5688
+          - goodix,gt911
+          - goodix,gt9110
+          - goodix,gt912
+          - goodix,gt9147
+          - goodix,gt917s
+          - goodix,gt927
+          - goodix,gt9271
+          - goodix,gt928
+          - goodix,gt9286
+          - goodix,gt967
+      - items:
+          - enum:
+              - goodix,gt970
+          - const: goodix,gt911
 
   reg:
     enum: [ 0x5d, 0x14 ]

-- 
2.55.0

