From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 18:26:28 +0700
Subject: [PATCH 1/2] dt-bindings: display: Add AYANEO Pocket DS lower panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-st7703-pocketds-lower-v1-1-e3db246589f4@gmail.com>
References: <20260723-b4-st7703-pocketds-lower-v1-0-e3db246589f4@gmail.com>
In-Reply-To: <20260723-b4-st7703-pocketds-lower-v1-0-e3db246589f4@gmail.com>
To: =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Purism Kernel Team <kernel@puri.sm>, Ondrej Jirman <megi@xff.cz>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784805987; l=1241;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=K1fR2kK/+LjIqWnZb42cj5ThTI+3DMxTN3z6sB3tVds=;
 b=cy2lnulZ67N5haOXuifPXUKDuZEmPIv/sPmoyjDawfnUEeURuOCsXpWoa4wsxGb0KgbavAbvw
 I1ebApNgX4lCGJ/xj4T0zvuNdCCglSO8GNxIz8K+kqHq0WgiC2j0Kud
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lower (secondary) 5.0" 1024x768 IPS LCD panel of the AYANEO Pocket DS
dual-screen handheld is driven by a Sitronix ST7703 DDIC, as identified
by its ST7703 manufacturer command set (SETEXTC 0xB9, SETMIPI 0xBA,
SETGIP1/2 0xE9/0xEA). Document its compatible alongside the other ST7703
panels.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 .../devicetree/bindings/display/panel/rocktech,jh057n00900.yaml         | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/rocktech,jh057n00900.yaml b/Documentation/devicetree/bindings/display/panel/rocktech,jh057n00900.yaml
index ebfc825b8346..91e06d6a6819 100644
--- a/Documentation/devicetree/bindings/display/panel/rocktech,jh057n00900.yaml
+++ b/Documentation/devicetree/bindings/display/panel/rocktech,jh057n00900.yaml
@@ -22,6 +22,8 @@ properties:
     enum:
       # Anberic RG353V-V2 5.0" 640x480 TFT LCD panel
       - anbernic,rg353v-panel-v2
+      # AYANEO Pocket DS lower 5.0" 1024x768 IPS LCD panel
+      - ayaneo,pocket-ds-lower-panel
       # GameForce Chi 3.5" 640x480 TFT LCD panel
       - gameforce,chi-panel
       # Powkiddy RGB10MAX3 5.0" 720x1280 TFT LCD panel

-- 
2.55.0

