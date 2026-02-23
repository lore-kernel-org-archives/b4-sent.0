From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH 0/3] Add ITE IT6162 MIPI DSI to HDMI bridge driver
Date: Mon, 23 Feb 2026 17:20:44 +0800
Message-Id: <20260223-upstream-6162-v1-0-ebcc66ccb1fe@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOwbnGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIyNj3dKC4pKi1MRcXTNDMyNdY3NTw1Rzi5S05MQUJaCegqLUtMwKsHn
 RsbW1AECYdJhfAAAA
X-Change-ID: 20260223-upstream-6162-3751e78dfcad
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771838463; l=1356;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=a8y9ien3dgTnIN1+y6wyUKNJA/hUgzMlmJd31F1z9wM=;
 b=U2VuZKFI4x72JUvV8RdMVHxPXE4vHWpvZ53F3EdDBmVeKoBSHCx8jbAb5XOcfBcyLnY3XVKgR
 /60M7RfPcsHA/cxEjvBct7l3E7YEoHqrt01mHuNvVM+vFTruz8bNOub
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the ITE IT6162 MIPI DSI to HDMI
bridge chip. The IT6162 is an I2C-controlled bridge that receives MIPI
DSI input and outputs HDMI signals.

The device supports the following configurations:
  - Single MIPI DSI input: up to 4K @ 30Hz
  - Dual MIPI DSI input (combined): up to 4K @ 60Hz

This series introduces:
  - dt-bindings: Add YAML binding document for ITE IT6162
  - drm/bridge: Add ITE IT6162 MIPI DSI to HDMI bridge driver
  - MAINTAINERS: Add entry for ITE IT6162 bridge driver

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Hermes Wu (3):
      drm/bridge: Add ITE IT6162 MIPI DSI to HDMI bridge driver
      dt-bindings: display: bridge: Add ITE IT6162 MIPI DSI to HDMI bridge
      MAINTAINERS: Add entry for ITE IT6162 MIPI DSI to HDMI bridge driver

 .../bindings/display/bridge/ite,it6162.yaml        |  156 ++
 MAINTAINERS                                        |    8 +
 drivers/gpu/drm/bridge/Kconfig                     |   17 +
 drivers/gpu/drm/bridge/Makefile                    |    1 +
 drivers/gpu/drm/bridge/ite-it6162.c                | 1876 ++++++++++++++++++++
 5 files changed, 2058 insertions(+)
---
base-commit: 38feb171b3f92d77e8061fafb5ddfffc2c13b672
change-id: 20260223-upstream-6162-3751e78dfcad

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

