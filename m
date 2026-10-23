From: Ishu Brar <patches@brar.si>
Subject: [PATCH 0/2] drm/panel: Add Samsung AMS644VK04 panel
Date: Fri, 23 Oct 2026 13:51:15 +0530
Message-Id: <20261023-panel-ams644vk04-v1-0-56096aecd0ff@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CMBBG4Vchs7ZJOzbE+CrGRYt/cbxU0kFiQ
 nh3iiy/xTkzKYpA6dzMVDCJyidXuEND3T3kHkZu1cSWW2f5aIaQ8TLhra3309N6g3SKHNmDmal
 mQ0GS3395ue7Wb3ygG7cPLcsKOeVzJXQAAAA=
X-Change-ID: 20261023-panel-ams644vk04-ef8b2b24e222
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792743679; l=1791;
 i=patches@brar.si; h=from:subject:message-id;
 bh=CmyaiwJWwoIMm1mdMGXzb84Z0m35G/pLGpSpkLPfqbk=;
 b=tWJfdchfzzcMsz0ZZmLr/J/rhEsP7HlXepsJOewkxdR9nqjFRuWQScnNSu8dZNObkScA23PTQ
 AjiVFN0U98sDzyZtaohbhJu7AvzvLqfvnWHRoTIyhZHbwRiHwjauXsP
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding and a driver for the Samsung AMS644VK04, a 6.44 inch
1080x2400 MIPI DSI command mode AMOLED panel with DSC, used in the
OnePlus Nord (SM7250).

The driver describes only the 90 Hz mode for now; the panel also does
60 Hz, which needs a way to pick the mode from the display pipeline that
I did not want to invent here.

One question for the reviewers: the DSC picture parameter set is the one
the downstream driver sends (DCS 0x9e, 88 bytes). It differs from what
drm_dsc_pps_payload_pack() computes for the same geometry, mainly
first_line_bpg_offset (15 downstream, 12 from the helper) and the last
rate control ranges. The msm DSI host fills the shared drm_dsc_config
with the helper values, so the encoder and the panel decoder use
different rate control parameters; the picture looks correct. If you
prefer, I can switch to the helper PPS once I have tested that the panel
accepts it.

Tested on a OnePlus Nord with the msm DSI host (a 7.3-rc7 based tree),
including suspend and resume. The SoC devicetree nodes are not part of
this series.

Signed-off-by: Ishu Brar <patches@brar.si>
---
Ishu Brar (2):
      dt-bindings: display: panel: Add Samsung AMS644VK04
      drm/panel: Add Samsung AMS644VK04 panel driver

 .../bindings/display/panel/samsung,ams644vk04.yaml |  76 +++++
 MAINTAINERS                                        |   7 +
 drivers/gpu/drm/panel/Kconfig                      |  15 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-samsung-ams644vk04.c   | 373 +++++++++++++++++++++
 5 files changed, 472 insertions(+)
---
base-commit: cf5d8e390e2ac2cfa24a50645efdbb9f0eebe65f
change-id: 20261023-panel-ams644vk04-ef8b2b24e222

Best regards,
--  
Ishu Brar <patches@brar.si>

