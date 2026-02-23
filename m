From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Mon, 23 Feb 2026 17:20:47 +0800
Subject: [PATCH 3/3] MAINTAINERS: Add entry for ITE IT6162 MIPI DSI to HDMI
 bridge driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-upstream-6162-v1-3-ebcc66ccb1fe@ite.com.tw>
References: <20260223-upstream-6162-v1-0-ebcc66ccb1fe@ite.com.tw>
In-Reply-To: <20260223-upstream-6162-v1-0-ebcc66ccb1fe@ite.com.tw>
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Pet.Weng@ite.com.tw, Kenneth.Hung@ite.com.tw, 
 Hermes Wu <Hermes.Wu@ite.com.tw>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771838463; l=984;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=FdNsL/OMQyTMBlZBr9eAfG0tA5xv05jqhySorqcp6Xs=;
 b=0HzTZgSkEC3qmk/LtTETSg9W2/WoK9wKwZ0hreljJRs1MtiuDSESV58tmJ2Bf/GLMYjpgWdup
 Ex8tPS1RSd5Cs/+4Qpum33A6Me8ieIPAdBXFaDovncdROTYuoWdci9h
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a MAINTAINERS entry for the newly introduced ITE IT6162 MIPI DSI
to HDMI bridge driver, covering the driver source file and the
device tree binding document.

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 6169bd4d7baccc6945363622b42e7286cbec7b88..8a6b5bf3f664247b45c66b37439d3debf6ee18b1 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -13485,6 +13485,14 @@ W:	https://linuxtv.org
 Q:	http://patchwork.linuxtv.org/project/linux-media/list/
 F:	drivers/media/tuners/it913x*
 
+ITE IT6162 MIPI DSI TO HDMI BRIDGE DRIVER
+M:	Hermes Wu <Hermes.wu@ite.com.tw>
+L:	dri-devel@lists.freedesktop.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/display/bridge/ite,it6162.yaml
+F:	drivers/gpu/drm/bridge/ite-it6162.c
+
+
 ITE IT6263 LVDS TO HDMI BRIDGE DRIVER
 M:	Liu Ying <victor.liu@nxp.com>
 L:	dri-devel@lists.freedesktop.org

-- 
2.34.1

