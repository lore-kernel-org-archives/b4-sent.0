From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v3 0/2] Add support for the BOE ILI97680A AMOLED panel of
 the Motorola Signature
Date: Fri, 20 Nov 2026 21:23:11 +0530
Message-Id: <20261120-vantage-panel-v3-0-00b306146240@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ7CIBBFr2JYi4EpJdaV9zAuBjpajJYGKrFpe
 nehbtzo8k3+ezOzSMFRZIfNzAIlF53vM1TbDbMd9lfirs3MQICWUmqesB8xnwfs6c4bo6FWiAI
 VsOwMgS7utfZO5w/Hp7mRHUukLDoXRx+m9WGSZfernSQXvBKmqU2rGpD6OGHn/c76ByvtBH9ty
 DYBGrXXqiaw3/ayLG8dsNlU+gAAAA==
X-Change-ID: 20261116-vantage-panel-9b6254aa0a42
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795189991; l=2895;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=aPbq/A5mUd6zF5e0lex8/Mk32wpdmYakJPFksuVGZXk=;
 b=lVbrb//Drjpuo+bKe5Gzl+EChAL+2FzEXujU0Tuh6l5/k7VLx7ROJAb3/R7ApP1ZmZxBAM2rn
 tATubxQMChRBrnzHn2Cx4RZTPui9NffftAawwJIx3JU9dfh0+7hh6mq
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Motorola Signature uses a 1264x2780 BOE AMOLED panel driven by an
Ilitek ILI97680A. It is a MIPI DSI command mode panel with DSC 1.2
compression on four lanes. This series adds the devicetree binding and a
driver for it.

Two things are specific to this panel. The DSC picture parameter set is
written to a vendor register on command page 7 instead of being sent as a
standard PPS packet, and the brightness range is 0 to 16180 over DCS.

Tested on a Motorola Signature with the msm DRM driver: the panel lights
up at its native resolution and Phosh renders on it.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v3:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter.
- Drop an unused include, fill the DSC configuration before adding the
  panel and describe the PPS layout in the comment.
- Link to v2: https://patch.msgid.link/20261116-vantage-panel-v2-0-e2ab48645e2c@yahoo.com

Changes in v2:
- Give the panel its own compatible, "motorola,vantage-boe-ili97680a",
  with "ilitek,ili97680a" as fallback: the mode, DSC settings and
  initialization sequence belong to this BOE panel, not to every
  ILI97680A panel. BOE's part number is not known, so the name follows
  the "<device>-<glass vendor>-<controller>" style of the Xiaomi and
  Lenovo NT36523 panels.
- Driver: match the panel compatible.
- Link to v1: https://patch.msgid.link/20261116-vantage-panel-v1-0-30b95bd49216@yahoo.com

To: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
To: Neil Armstrong <neil.armstrong@linaro.org>
To: Jessica Zhang <jesszhan0024@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>
To: Maxime Ripard <mripard@kernel.org>
To: Thomas Zimmermann <tzimmermann@suse.de>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Venkat Yadlapati (2):
      dt-bindings: display: panel: Add Ilitek ILI97680A
      drm/panel: Add Ilitek ILI97680A DSC command mode panel driver

 .../bindings/display/panel/ilitek,ili97680a.yaml   |  75 ++++
 MAINTAINERS                                        |   6 +
 drivers/gpu/drm/panel/Kconfig                      |  16 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-ilitek-ili97680a.c     | 495 +++++++++++++++++++++
 5 files changed, 593 insertions(+)
---
base-commit: 39e407b553ec15d4a233b651531ad431ed7542be
change-id: 20261116-vantage-panel-9b6254aa0a42

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

