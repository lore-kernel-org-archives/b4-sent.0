From: David Heidelberg <david@ixit.cz>
Date: Sat, 13 Sep 2025 21:19:49 +0200
Subject: [PATCH v6 3/3] dt-bindings: display: panel: Add Novatek NT35596S
 panel bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250913-nt35596s-v6-3-b5deb05e04af@ixit.cz>
References: <20250913-nt35596s-v6-0-b5deb05e04af@ixit.cz>
In-Reply-To: <20250913-nt35596s-v6-0-b5deb05e04af@ixit.cz>
To: Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Molly Sophia <mollysophia379@gmail.com>, 
 Arnaud Ferraris <arnaud.ferraris@collabora.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1713; i=david@ixit.cz;
 h=from:subject:message-id; bh=lFoP3Jmjexe60vWrVFSdH2SLqrIeKo/VFBht7BKKVLc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoxcPWenKVF1BK8oEurKoF2JGZ9fs17xjEBq+ad
 nLmW22lVKGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaMXD1gAKCRBgAj/E00kg
 ckPSD/0apPokMVlQ7NkcKcqNNKRt7eEHs4tDWTXJIK7FXwLs0StRKtIg70lfdXdy3JCMhEOogEM
 OMZXA3Cyts0ez2Jg392TkgFk6P7Xaux4ia8v/1LzS/ckjqNRgQtbdHiAlXkCtcm0PnO+mTlUBUX
 PQPuJx8kSnYnKv4TDWRKKj1KpV2ACOPAYaaaY9wC60D6EgIrq6Qt/97jZPNRptlZpjNLmGD8B0f
 hn+U1OAGucge0s1O/z/xMyFpEwL8P5T26vfykwxuzmaaGw3qFNELC+WPmiH80ZljZtzHTy3UGi+
 4sWruE8Y5JO2xrLCzSKffjyJ1ciBageAJudf8bC6MUsTkojpnnY0hhKuNAynL6Z0LltT7iZe/S4
 u63Uwb4yeiVMIsb1ireT1O7a8PxFzgYcPIJcSYhwMnMZA/abeIE5PU7gzBrvg0eoYdbN37fs8We
 lZSBaQ+sLKgO+VQfW4kB2Df3E2AFWC+oU5SweY3XDkpY9s95i7u4Drs0YTVLQDG4qCcegLj/e7b
 wAk3pvbSFdulrYISf1p84hyXwbHT+rcQwpUgqZ3Dltmrvb8sfrMx4lmrjm8Y0kGw/kOJwMQN/tY
 pAck29CBBWV4/MygzCDUUXUET2qFzxBIs9iJy9MwFFBecpVDS5UK0190SMaLOmqDS4jtZlgLpWx
 uiJR9/I7KgdKqFg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Molly Sophia <mollysophia379@gmail.com>

Add documentation for "novatek,nt35596s" panel.

Signed-off-by: Molly Sophia <mollysophia379@gmail.com>
Signed-off-by: Arnaud Ferraris <arnaud.ferraris@collabora.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 .../bindings/display/panel/novatek,nt36672a.yaml    | 21 ++++++++++++++-------
 1 file changed, 14 insertions(+), 7 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/novatek,nt36672a.yaml b/Documentation/devicetree/bindings/display/panel/novatek,nt36672a.yaml
index 800a2f0a4dad98954ef60c3bb04d8eb2243cae7a..d7036ab46382f7b6200cc263ba7e93856386919f 100644
--- a/Documentation/devicetree/bindings/display/panel/novatek,nt36672a.yaml
+++ b/Documentation/devicetree/bindings/display/panel/novatek,nt36672a.yaml
@@ -20,14 +20,21 @@ allOf:
 
 properties:
   compatible:
-    items:
-      - enum:
-          - tianma,fhd-video
-      - const: novatek,nt36672a
+    oneOf:
+      - items:
+          - enum:
+              - jdi,fhd-nt35596s
+          - const: novatek,nt35596s
+
+      - items:
+          - enum:
+              - tianma,fhd-video
+          - const: novatek,nt36672a
+
     description: This indicates the panel manufacturer of the panel that is
-      in turn using the NT36672A panel driver. This compatible string
-      determines how the NT36672A panel driver is configured for the indicated
-      panel. The novatek,nt36672a compatible shall always be provided as a fallback.
+      in turn using the NT36672A or the NT35596S panel driver. This compatible
+      string determines how the panel driver is configured for the indicated
+      panel.
 
   reg:
     maxItems: 1

-- 
2.51.0

