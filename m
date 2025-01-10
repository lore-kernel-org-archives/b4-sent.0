From: Ao Xu <ao.xu@amlogic.com>
Date: Fri, 10 Jan 2025 13:39:51 +0800
Subject: [PATCH 01/11] dt-bindings: display: meson-dw-hdmi: Add compatible
 for S4 HDMI controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250110-drm-s4-v1-1-cbc2d5edaae8@amlogic.com>
References: <20250110-drm-s4-v1-0-cbc2d5edaae8@amlogic.com>
In-Reply-To: <20250110-drm-s4-v1-0-cbc2d5edaae8@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: dri-devel@lists.freedesktop.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Ao Xu <ao.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736487593; l=876;
 i=ao.xu@amlogic.com; s=20250103; h=from:subject:message-id;
 bh=/06xHmC2myfGLoM8tpTANbPOABYZF56wo8NJNiKgZ5A=;
 b=J74TFdNjfeuf4xmz4NKNLHVau7fIMmNSUihqIqgeyFjm92lB/udlEzM3roEpMg+hkQ+N4X7s8
 UeGx5QN1XU3Di8eU0SCdOogQj+QOImkjRWWthXzpVE0fDQoU6NLI3e7
X-Developer-Key: i=ao.xu@amlogic.com; a=ed25519;
 pk=c0TSXrwQuL4EhPVf3lJ676U27ax2yfFTqmRoseP/fA8=
X-Endpoint-Received: by B4 Relay for ao.xu@amlogic.com/20250103 with auth_id=308
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree document for S4 HDMI controller

Signed-off-by: Ao Xu <ao.xu@amlogic.com>
---
 Documentation/devicetree/bindings/display/amlogic,meson-dw-hdmi.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/display/amlogic,meson-dw-hdmi.yaml b/Documentation/devicetree/bindings/display/amlogic,meson-dw-hdmi.yaml
index 84d68b8cfccc86fd87a6a0fd2b70af12e51eb8a4..6e0a8369eee915fab55af24d450a6c40e08def38 100644
--- a/Documentation/devicetree/bindings/display/amlogic,meson-dw-hdmi.yaml
+++ b/Documentation/devicetree/bindings/display/amlogic,meson-dw-hdmi.yaml
@@ -55,6 +55,7 @@ properties:
           - const: amlogic,meson-gx-dw-hdmi
       - enum:
           - amlogic,meson-g12a-dw-hdmi # G12A (S905X2, S905Y2, S905D2)
+          - amlogic,meson-s4-dw-hdmi # S4 (S905Y4)
 
   reg:
     maxItems: 1

-- 
2.43.0

