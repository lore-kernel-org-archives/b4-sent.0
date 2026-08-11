From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH 0/2] Add panel driver for Novatek NT37703
Date: Tue, 11 Aug 2026 01:52:32 -0400
Message-Id: <20260811-nt37703-bup-v1-0-34ad42b064a3@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDWpNmlxFbEwNRiLkhaRiLsrl
 m/x/wWRAlOEOrsg0MGRF59Q5Bm4qfMjCe6TQUllpFVG+E1bK7XAfRVlh4hWV8YZglSsgQY+v1v
 T/o47zuS2dwH3/QDyeLAmbwAAAA==
X-Change-ID: 20260726-nt37703-bup-8abbb7396c6e
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786427559; l=1257;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=VnBFGa4EyeTs0i/DZjjSshOWY9ZN8a+HoVYsbHsIWds=;
 b=BEaOBS/j9sREN5fLM7EsF6azUtpvnMDsvsU10EN6WHpIraO3NhGztIQ3sgDDmT2RrcthgoD5D
 JE1Dy+97geSBWs3/AWGIE5lpz49h+HI9o02awYYKipOzscFjdOqhUuG
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a driver and bindings for panels based on this display
driver IC.
Initial support is added for the Tianma "v2" panel found in the Motorola
ThinkPhone by motorola.
This panel has no model number and is only identified with versions.
There seem to exist three versions of Tianma panels: v0 (no version), v1
and v2.
Only v2 has been able to be tested.
The added driver should in theory make it fairly easy to add new panels
in the future.
I tried to be as careful as possible with that.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Esteban Urrutia (2):
      dt-bindings: display: panel: Add bindings for Novatek NT37703
      drm/panel: Add driver for Novatek NT37703 based panels

 .../bindings/display/panel/novatek,nt37703.yaml    |  78 ++++
 MAINTAINERS                                        |   6 +
 drivers/gpu/drm/panel/Kconfig                      |  13 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-novatek-nt37703.c      | 467 +++++++++++++++++++++
 5 files changed, 565 insertions(+)
---
base-commit: 3d08ff75a47a3e7e2ab45a3bcab6723b4d906422
change-id: 20260726-nt37703-bup-8abbb7396c6e

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

