From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v2 0/2] Add support for the BOE ILI97680A AMOLED panel of
 the Motorola Signature
Date: Mon, 16 Nov 2026 13:10:11 +0530
Message-Id: <20261116-vantage-panel-v2-0-e2ab48645e2c@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ7CIBREr9L8tRhASlJX3sN08Wm/FqPQABKbp
 ncX6trlm8y8WSFSsBTh3KwQKNtovSsgDw0ME7o7MTsWBsmlFkJoltElLPGMjp6sM1q2CpGjklA
 2c6Cb/ey+a//j+DYPGlKV1MZkY/Jh2Q+zqL1/7iwYZyduutaMqpNCXxacvD8O/gX9tm1fPIqnK
 rwAAAA=
X-Change-ID: 20261116-vantage-panel-9b6254aa0a42
To: Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794814811; l=1949;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=8ZaUQLu3CSlV2D2wl6s2Z6g9bA3Qymqgd8aSrdWtrqU=;
 b=ddZgpxcYoUiC6iWTgh1UxYw/wtjG1pa3EKFWXDlgytu8Y5qdEmqdNfN1fdQruopRKVOY1Os9v
 fDEDDaF6hjuBwVJhS2KUpW2DGa6pAe7s3FhQ7807GB5NEQc+QJzG30Q
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
Changes in v2:
- Give the panel its own compatible, "motorola,vantage-boe-ili97680a",
  with "ilitek,ili97680a" as fallback: the mode, DSC settings and
  initialization sequence belong to this BOE panel, not to every
  ILI97680A panel. BOE's part number is not known, so the name follows
  the "<device>-<glass vendor>-<controller>" style of the Xiaomi and
  Lenovo NT36523 panels.
- Driver: match the panel compatible.
- Link to v1: https://patch.msgid.link/20261116-vantage-panel-v1-0-30b95bd49216@yahoo.com

---
Venkat Yadlapati (2):
      dt-bindings: display: panel: Add Ilitek ILI97680A
      drm/panel: Add Ilitek ILI97680A DSC command mode panel driver

 .../bindings/display/panel/ilitek,ili97680a.yaml   |  75 ++++
 MAINTAINERS                                        |   6 +
 drivers/gpu/drm/panel/Kconfig                      |  16 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-ilitek-ili97680a.c     | 494 +++++++++++++++++++++
 5 files changed, 592 insertions(+)
---
base-commit: 39e407b553ec15d4a233b651531ad431ed7542be
change-id: 20261116-vantage-panel-9b6254aa0a42

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

