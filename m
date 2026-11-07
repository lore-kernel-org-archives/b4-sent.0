From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sat, 07 Nov 2026 20:47:24 +0100
Subject: [PATCH 1/3] dt-bindings: vendor-prefixes: Add Anapass
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-b4-ana38407-v1-1-c8b33147110a@dxdmail.cc>
References: <20261107-b4-ana38407-v1-0-c8b33147110a@dxdmail.cc>
In-Reply-To: <20261107-b4-ana38407-v1-0-c8b33147110a@dxdmail.cc>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794080847; l=794;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=2HvAMxJc/diBPtN/JLnus3Kqq4WWx1yv+UIkhTrhRk4=;
 b=5+MmzenMYLvm3RxC/YRhDPN6/0nfSIFq1Wd+rDv57fQhjKMbdyWQxfBWm6n/I6If+DYI8YNyq
 pwekuVGrR4UCuOA59Ctg8dVAbWKK5S77jzXiiqn0HSyRi5AT7hnYgUO
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a vendor prefix for Anapass, Inc., a display driver IC vendor.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 5471a06f93f1..b117fce91102 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -136,6 +136,8 @@ patternProperties:
     description: AMS-Taos Inc.
   "^analogix,.*":
     description: Analogix Semiconductor, Inc.
+  "^anapass,.*":
+    description: Anapass, Inc.
   "^anbernic,.*":
     description: Anbernic
   "^andestech,.*":

-- 
2.56.0

