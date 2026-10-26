From: Ishu Brar <patches@brar.si>
Subject: [PATCH v2 0/2] drm/panel: Add Samsung AMS644VK04 panel
Date: Mon, 26 Oct 2026 22:09:31 +0530
Message-Id: <20261026-panel-ams644vk04-v2-0-e88cafb3e577@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32Nyw6CMBBFf4XM2poy1kZd+R+GRQtTGR+FdLDRE
 P5dwL3Lk5x77ghCiUngVIyQKLNwF2fATQF16+KVFDczA2q0pcad6l2kh3JPscbkuzaKwsGjR0O
 ICPOsTxT4vSYv1Y/l5W9UD0tnMVqWoUuf9TOXi/cnn0ul1d7qo3VUNzqEs08ubYWhmqbpC//zP
 73AAAAA
X-Change-ID: 20261023-panel-ams644vk04-ef8b2b24e222
To: Ishu Brar <patches@brar.si>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793032778; l=2277;
 i=patches@brar.si; h=from:subject:message-id;
 bh=4KvuWUHaPdgXq8ehofY3K9oc4EVZW4Z4TVVrcbXXOJY=;
 b=oSUMPeh/n1fzasZaiOnn9y+qAgPxIn7YgjYD7xmaw9+shBNZFQr2yzmiEhCb8tcSEzXPwGe6s
 ALIYNO0WNnJAZwe8hZCAf7ODwNP07CZqLC1Sgy1iALMHiilk8zatLUl
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

Tested on a OnePlus Nord with the msm DSI host (a 7.3-rc7 based tree),
including suspend and resume. The SoC devicetree nodes are not part of
this series.

---
Changes in v2:
- Rebased on drm-misc-next
- Dropped the T: entry from MAINTAINERS (not a committer)
- Collected Reviewed-by on the binding patch
- Send the PPS packed by drm_dsc_pps_payload_pack() with
  mipi_dsi_picture_parameter_set_multi() instead of the downstream blob,
  so the panel uses the same DSC parameters as the DSI host
- Binding example: sorted properties, dropped the unused endpoint label
  (dt-check-style strict)
- Link to v1: https://patch.msgid.link/20261023-panel-ams644vk04-v1-0-56096aecd0ff@brar.si

To: Ishu Brar <patches@brar.si>
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
Ishu Brar (2):
      dt-bindings: display: panel: Add Samsung AMS644VK04
      drm/panel: Add Samsung AMS644VK04 panel driver

 .../bindings/display/panel/samsung,ams644vk04.yaml |  76 +++++
 MAINTAINERS                                        |   6 +
 drivers/gpu/drm/panel/Kconfig                      |  17 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-samsung-ams644vk04.c   | 356 +++++++++++++++++++++
 5 files changed, 456 insertions(+)
---
base-commit: 650385a0fd0ea6475a17d39a20ec90470c7a4c67
change-id: 20261023-panel-ams644vk04-ef8b2b24e222

Best regards,
--  
Ishu Brar <patches@brar.si>

