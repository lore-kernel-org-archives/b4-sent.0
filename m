From: Nizat Mikayilli <nacht@dxdmail.cc>
Subject: [PATCH v2 0/3] drm/panel: Add Anapass ANA38407 DDIC
Date: Thu, 19 Nov 2026 20:01:11 +0100
Message-Id: <20261119-b4-ana38407-v2-0-bddc251bd43f@dxdmail.cc>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22MOw7CMBBErxJtjZF/wYaKe6AU6w9kJUgiG1lBk
 e+OSU03b0bzNsgxUcxw6TZIsVCmeWogDx34EadHZBQag+TyJAQ3zGmGEyqrW1bi3PfondVooD2
 WFO+07rbb0Hik/J7TZ5cX8Wv/e4pgnHnrlBLatBWvYQ0vpOfRexhqrV+gOTCPpwAAAA==
X-Change-ID: 20261107-b4-ana38407-31955acb84a7
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, Nizat Mikayilli <nacht@dxdmail.cc>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795114874; l=1711;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=Gxjj1oEcl9xXswoh+L+3EaxDdop6cBisF4OLFm8PBxw=;
 b=wOSo7HJNMi7LWMB+RqmTmdSRuTNTi0AU8k/qpmErX6tCqmjxONZkL3CifLlJfs5OE4KQWC78A
 iPCbsuAkUlLCR93zJ5YVOzzYYID0vGFUdpGQeH2Kg8Y1ifvnlhQA4Tx
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a driver for the Samsung AMSA10FA01, the 2560x1600
AMOLED panel of the Samsung Galaxy Tab S9 Wi-Fi (SM8550). It is a
command mode DSI panel with DSC, driven by an Anapass ANA38407 DDIC.
The binding and driver are named after the DDIC.

Only the 120 Hz mode of panel revision D is supported. The init
sequence comes from the vendor panel data, without the
brightness-dependent gamma, HBM and ELVSS writes. A fixed delay
replaces the vendor's wait on the TCON_RDY pin.

Tested on the tablet: cold and warm boot, hand-off from the bootloader
splash, brightness and blank/unblank. The board DT follows separately.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
Changes in v2:
- Dropped port from the required properties (Krzysztof)
- Added Krzysztof's Acked-by to the vendor prefix patch
- Link to v1: https://lore.kernel.org/r/20261107-b4-ana38407-v1-0-c8b33147110a@dxdmail.cc

---
Nizat Mikayilli (3):
      dt-bindings: vendor-prefixes: Add Anapass
      dt-bindings: display: panel: Document Anapass ANA38407 DDIC
      drm/panel: Add driver for Anapass ANA38407 DDIC

 .../bindings/display/panel/anapass,ana38407.yaml   |  68 +++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   6 +
 drivers/gpu/drm/panel/Kconfig                      |  15 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-anapass-ana38407.c     | 320 +++++++++++++++++++++
 6 files changed, 412 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261107-b4-ana38407-31955acb84a7

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

