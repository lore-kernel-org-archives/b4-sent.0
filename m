From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/4] drm/panel: Support Retroid Pocket 6 panel
Date: Fri, 14 Aug 2026 13:17:14 -0500
Message-Id: <20260814-rp6-panel-v1-0-111c1aeccf0f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22O0WrDMAxFfyX4eQY5tiXVv1L64CjKZljT1O7CR
 um/L0uhT3s8Qvdw7qZpLdpM6u6m6lpaucwbuLfOyEee39WWcWPTQ4/gHdu6oF3yrJ+W0XGAGAA
 dmu1/qTqV7911PD256vVrU96eRzPkplYu53O5pS4EokzsKeRI4hkOg6M+jx5ENA9jDiyBZFe/U
 lK3h/SObP6Z7VUaxwjWoQAN6EftMa2H/yYMf+2vBUfhQAgTTj6tzpwej1/II9LrDAEAAA==
X-Change-ID: 20260318-rp6-panel-861840540616
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786731444; l=2531;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=05UlI8U8+ox12Iu078tYqJXr6YhBgqKRLtpJyQ3O4/4=;
 b=scEWgA4YR3TDfadbQQ+muEYFqhjR7300Z8EJM0Yt/Wm2tOSAFBnusy8gRg+Lhwc1gX1yDtSPl
 tOsVyttPGi+CUM4pncKOQzleknM/tkIEDX1QiI0Yc2Oj/uzVpIVtWP/
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This panel uses a Visionox VTDR6130 DDIC. There is an existing driver
for this ddic, however it is currently hardcoded for a panel used on
several Qualcomm devkits. This series sets up the driver to support
multiple panels, then adds the RP6 panel. It also adds support for
rotation as the RP6 panel is mounted sideways.

This depends on the Retroid Pocket dt series [0] for the vendor prefix
patch. That series depends on the AYN dt series [1] to apply cleanly.
    
[0] https://lore.kernel.org/linux-arm-msm/20260808-rp-qcs8550-v1-0-a5a365ba3dc5@gmail.com/
[1] https://lore.kernel.org/linux-arm-msm/20260727-ayn-qcs8550-v9-0-e3db456e10e5@gmail.com/

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (4):
      dt-bindings: display: visionox,vtdr6130: Add Retroid Pocket 6 panel
      drm/panel: visionox-vtdr6130: Add panel orientation support
      drm/panel: visionox-vtdr6130: Modularize panel config
      drm/panel: visionox-vtdr6130: Add Retroid Pocket 6 panel

 .../bindings/display/panel/visionox,vtdr6130.yaml  |   8 +-
 drivers/gpu/drm/panel/panel-visionox-vtdr6130.c    | 225 ++++++++++++++++++---
 2 files changed, 201 insertions(+), 32 deletions(-)
---
base-commit: 4477a78374a57c3809b172ad30cceabda48c47c6
change-id: 20260318-rp6-panel-861840540616
prerequisite-change-id: 20260217-ayn-qcs8550-16c07b63de26:v9
prerequisite-patch-id: 17ba304f7a8a08cc78f98e198db9c51f4786a22c
prerequisite-patch-id: 21873631f5dcdb9bbbdb5c20c3f5e9816cc405f9
prerequisite-patch-id: bf7b5dea0097cbbdf04929a4246d1fc65c607ea8
prerequisite-patch-id: d7f546eddc96a4f31a1e681abddbc96bd68abb32
prerequisite-patch-id: d40d784ad8efbb1204c024408be2067725a06cf2
prerequisite-patch-id: 25bbd55199a8250a912ef542b31f43dd5ccdbc90
prerequisite-change-id: 20260808-rp-qcs8550-85c84760f6f3:v1
prerequisite-patch-id: 17ba304f7a8a08cc78f98e198db9c51f4786a22c
prerequisite-patch-id: 21873631f5dcdb9bbbdb5c20c3f5e9816cc405f9
prerequisite-patch-id: bf7b5dea0097cbbdf04929a4246d1fc65c607ea8
prerequisite-patch-id: d7f546eddc96a4f31a1e681abddbc96bd68abb32
prerequisite-patch-id: d40d784ad8efbb1204c024408be2067725a06cf2
prerequisite-patch-id: 25bbd55199a8250a912ef542b31f43dd5ccdbc90
prerequisite-patch-id: c79dacb2a8ca1298387bc9bc4a543de97c670a50
prerequisite-patch-id: 9c058fb9b13442f5434b8aaa2f1907eff1b43684
prerequisite-patch-id: c13130099b60aa7c412181e99070718eb2c68ecd
prerequisite-patch-id: d0dad3c4fa9c4b98e6cc53bbd0874df9113ab5f6

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

