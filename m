From: Alexandre Marquet <tb@a-marquet.fr>
Subject: [PATCH 0/3] DRM Google Nexus 10 display support
Date: Tue, 27 Oct 2026 13:01:41 +0100
Message-Id: <20261027-drm-misc-next-manta-auxbus-v1-0-3a45c3cf531d@a-marquet.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKWS4GoC/yXMSw7CIBAA0Ks0s3YSSuP3KqaLAaY6JqBhwJA0v
 buoy7d5KyhnYYXLsELmt6g8U8e4G8DfKd0YJXSDNfYwGjthyBGjqMfErWCkVAipNlcVj27vzBL
 OZKYT9OCVeZH2y6/z31rdg335jrBtHzB4lBJ+AAAA
X-Change-ID: 20261023-drm-misc-next-manta-auxbus-7b5b0fd9a038
To: Andrzej Hajda <andrzej.hajda@intel.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Robert Foss <rfoss@kernel.org>, 
 Laurent Pinchart <Laurent.pinchart@ideasonboard.com>, 
 Jonas Karlman <jonas@kwiboo.se>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Luca Ceresoli <luca.ceresoli@bootlin.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jingoo Han <jingoohan1@gmail.com>, Inki Dae <inki.dae@samsung.com>, 
 Seung-Woo Kim <sw0312.kim@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Douglas Anderson <dianders@chromium.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Lukas Timmermann <linux@timmermann.space>, 
 Henrik Grimler <henrik@grimler.se>, Hendrik Noack <hendrik-noack@gmx.de>, 
 Alexandre Marquet <tb@a-marquet.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793102508; l=1681;
 i=tb@a-marquet.fr; s=20261023; h=from:subject:message-id;
 bh=f1oj+Wwd1+MToNnaYOltu8jkeNrOGt2+b4GvKUkx/kE=;
 b=Q0u6yl+Xldh8lvEwFZiCC6j8shd8C4WEjiYDtBxaeb0XJroPskxBtvIJTcwV/EGuT4XB09eLL
 r+xuM9wpOfMA+j1X2uFV2iSJPDad00KP9+96VeELoZoM+EysL0shsAK
X-Developer-Key: i=tb@a-marquet.fr; a=ed25519;
 pk=zVRSO6FDK46rqmeA2GuzAhM24eFlUq1QpmXi9/KCFyk=
X-Endpoint-Received: by B4 Relay for tb@a-marquet.fr/20261023 with auth_id=1334
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series proposes to add an entry in panel_edp for the panel used in
the Google Nexus 10, as well as two modifications in analogix_dp and exynos_dp,
which allow to effectively enable the use of aux-bus on the platform.

It is actually a follow up of [1], with only the drm patches kept, as suggested
in [2].

I preferred not to label this series as v2, and opted to change the title
instead. Indeed, this series contains only drm patches, which are actually all
new with respect to [1], following the guidance received to use aux-bus if
possible (in [3]), which it is, building upon recent work on analogix_dp, and
after applying the patches of this series.

[1] https://lore.kernel.org/all/20260423-manta-display-v1-0-196f80c5673a@timmermann.space/
[2] https://lore.kernel.org/all/20260425-uncovered-otter-of-sunshine-d00ed0@quoll/
[3] https://lore.kernel.org/all/CAD=FV=VNvPtG_f1W942SKJfM4ptK8Wvd-nZs4geBCG3bO_A0BA@mail.gmail.com/

Signed-off-by: Alexandre Marquet <tb@a-marquet.fr>
---
Alexandre Marquet (3):
      drm/bridge: analogix_dp: deassert DP_PHY_PD on power-on for exynos
      drm/exynos: exynos_dp: change poweron/off to encoder enable/disable
      drm/panel_edp: Add SEC LTL101DL02-002 panel

 drivers/gpu/drm/bridge/analogix/analogix_dp_reg.c | 19 +++++++----
 drivers/gpu/drm/exynos/exynos_dp.c                | 40 ++++++++---------------
 drivers/gpu/drm/panel/panel-edp.c                 |  2 ++
 3 files changed, 28 insertions(+), 33 deletions(-)
---
base-commit: cf61bef3801c3c9d0d8c39026b7b2fb242898a3a
change-id: 20261023-drm-misc-next-manta-auxbus-7b5b0fd9a038

Best regards,
--  
Alexandre Marquet <tb@a-marquet.fr>

