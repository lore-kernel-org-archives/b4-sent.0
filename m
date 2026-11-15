From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH 0/2] Add support for the BOE ILI97680A AMOLED panel of the
 Motorola Signature
Date: Mon, 16 Nov 2026 01:50:20 +0530
Message-Id: <20261116-vantage-panel-v1-0-30b95bd49216@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QpAMBTG8VdZ59rKFiteRS6OOTjSaBspeXfD5
 e+r739BIM8UoBYXeDo48OoSVCbATuhGktwng861UUoZeaCLmOYNHS2y6owuC8QcCw3ps3ka+Px
 6Tfs77N1MNr4RuO8HSWa8b3EAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774020; l=1422;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=KQjjdkBwQ6+2i8+eBdXH5aAGDT7OhKlPtqt4R3BsY5g=;
 b=ejJ6ZaTaQUZI4fGanN319Tuz3hrXmYLxTAEG/DwdOoVn1j/i3x252I00pV4uqEVZ7xTMv1JYI
 +oHkJ/z909GBblpPtC3OoDvVyFnicdwp8njYNG0RDtpUIPDB98ulDg7
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
Venkat Yadlapati (2):
      dt-bindings: display: panel: Add Ilitek ILI97680A
      drm/panel: Add Ilitek ILI97680A DSC command mode panel driver

 .../bindings/display/panel/ilitek,ili97680a.yaml   |  70 +++
 MAINTAINERS                                        |   6 +
 drivers/gpu/drm/panel/Kconfig                      |  16 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-ilitek-ili97680a.c     | 494 +++++++++++++++++++++
 5 files changed, 587 insertions(+)
---
base-commit: 39e407b553ec15d4a233b651531ad431ed7542be
change-id: 20261116-vantage-panel-9b6254aa0a42

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

