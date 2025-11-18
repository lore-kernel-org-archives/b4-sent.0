From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 12:30:37 +0100
Subject: [PATCH v3 2/8] dt-bindings: panel: sw43408: adjust to reflect the
 DDIC and panel used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-pixel-3-v3-2-317a2b400d8a@ixit.cz>
References: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
In-Reply-To: <20251118-pixel-3-v3-0-317a2b400d8a@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sumit Semwal <sumit.semwal@linaro.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: phodina@protonmail.com, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1609; i=david@ixit.cz;
 h=from:subject:message-id; bh=rtFg229e6XLKb3HRj7KZLISBROfCdBSLoe51Y4DeXU4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHFjgXde2YPgCteVu+xuiR0bTzTZi44wHE/G+T
 TmtOdgJbVmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRxY4AAKCRBgAj/E00kg
 coVGD/48ND8fm7+63DnZhZkBaRJP80bZWosvdXkjNGgE7xG2gFtWYdrNfujStsizIpp4spuIYc9
 NQZKWJWnOszF1jyKSki0nTDH7DpigT5Y9wL2M9zWwIOwSpZsud2gr6d6fvf5jlyxfas62KdKD4c
 czS/4tF1kvo0/lNOUAK4eUVSjEcZ/1Wx9SHhJeKeb0NxaWxZ6iXX7tAZPQhqgUui3pN7fZ8I8DF
 CokdETV/6P2z0kyd5Ei5AqVswOs/h3x9S2jd3GiXASmvjjfj46aJdUANf1lJ75mjgWYLzFDTd+Y
 zXEZZGe/jIZA4ETTaCgvimkDa+dl+1Rz3rwcuz0b1qDs55fXARBugmsLFtS2OsiRnouDos4jcg3
 lDZNBCJhRNz0bH33g06cysNWPECKZmvTX0NdRwkFPnpHGbRERGDE5H5FFtLnS4ZF0fbLetRBI9y
 XSnFaonEpo5Gs4qOrDxjAjo5MIyBtpjqAVcs5svqGDEvQk7D/UM2Q/kBkcrRu2Ua0Aal5L9RXna
 7mSUOUj/7OhLODFdtNLA8BgLdxoEeOjuSs3Y3r0ThnxW9+CrUeLH0q7JsVbFXy2YaS2bilVPi0R
 mycCqCcaG9jCUzxkvvQZnEsN3QliKbA4fBv43wVGs9JIPonDWtjDrKpof1apTjQH5ajTs245E7l
 2U7Cv2K2XRIH5TA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible for used LG panel.
SW43408 is not panel, but DDIC. The panel itself is the
LG LH546WF1-ED01, so introduce combined compatible for it.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/display/panel/lg,sw43408.yaml         | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml b/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml
index 2219d3d4ac43b..bcf5efac6902c 100644
--- a/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml
+++ b/Documentation/devicetree/bindings/display/panel/lg,sw43408.yaml
@@ -4,14 +4,16 @@
 $id: http://devicetree.org/schemas/display/panel/lg,sw43408.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: LG SW43408 1080x2160 DSI panel
+title: LG SW43408 AMOLED DDIC
 
 maintainers:
   - Casey Connolly <casey.connolly@linaro.org>
 
 description:
-  This panel is used on the Pixel 3, it is a 60hz OLED panel which
-  required DSC (Display Stream Compression) and has rounded corners.
+  The SW43408 is display driver IC with connected panel.
+
+  LG LH546WF1-ED01 panel is used on the Pixel 3, it is a 60hz OLED panel
+  which required DSC (Display Stream Compression) and has rounded corners.
 
 allOf:
   - $ref: panel-common.yaml#
@@ -19,6 +21,9 @@ allOf:
 properties:
   compatible:
     items:
+      - enum:
+            # LG 5.46 inch, 1080x2160 pixels, 18:9 ratio
+          - lg,sw43408-lh546wf1-ed01
       - const: lg,sw43408
 
   reg:

-- 
2.51.0

