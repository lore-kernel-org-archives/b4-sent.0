From: Alexandre MINETTE <contact@alex-min.fr>
Subject: [PATCH 0/2] drm/msm/mdp4: fix intermittent blue screen on Galaxy
 S4
Date: Thu, 11 Jun 2026 08:07:45 +0200
Message-Id: <20260611-mainline-fix-mdp4-blue-screen-sending-v1-v1-0-22925600e4f2@alex-min.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALFQKmoC/yXNwQ6CMBCE4Vche3aTFqQkvorxUNoR18BKWiAmh
 He36vE7zD87ZSRBpku1U8ImWV5aYE8VhYfXASyxmGpTO+Os4cmLjqLgu7x5ivOZ+3EF55AA5Qy
 NogNvlo1ruth5F5q2pZKbE8rkd3W9/Z3X/omwfPt0HB/C2qJDjAAAAA==
X-Change-ID: 20260610-mainline-fix-mdp4-blue-screen-sending-v1-0637d7a6c355
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781158087; l=1297;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=81muFtNZlIN5I+ReHetL0p5x3A+MyYaxxxEAsQdgsiE=;
 b=0xbJVqU4awXIOs3QAV1exSkY/TNPZmxrn4rSiwfmmxX3PgynjiiF2s3u7oOvRNUQsQoI3dQBY
 GNcWij60CaXBzgqdahAot4Dc5UraLukFX185Itt9H67s6HDMhZDVZEp
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes an intermittent blue screen seen on the Samsung
Galaxy S4 with the MDP4 display controller. The issue happens on roughly
half of boots.

The first patch keeps the AXI/bus clock enabled while a CRTC is active,
so scanout does not lose bus access while the display pipeline is still
running.

The second patch handles the case where firmware left the display
pipeline enabled before Linux takes over. In that case, the required
display clocks are kept enabled until the first DRM modeset, where the
driver takes ownership of the pipeline.

Tested on a Samsung Galaxy S4 GT-I9505, codename jflte.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
Alexandre MINETTE (2):
      drm/msm/mdp4: keep the bus clock enabled while a CRTC is active
      drm/msm/mdp4: keep inherited display clocks enabled until modeset

 drivers/gpu/drm/msm/disp/mdp4/mdp4_crtc.c |   3 +
 drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.c  | 108 +++++++++++++++++++++++++++++-
 drivers/gpu/drm/msm/disp/mdp4/mdp4_kms.h  |   8 +++
 3 files changed, 118 insertions(+), 1 deletion(-)
---
base-commit: acb7500801e98639f6d8c2d796ed9f64cba83d3a
change-id: 20260610-mainline-fix-mdp4-blue-screen-sending-v1-0637d7a6c355

Best regards,
--  
Alexandre MINETTE <contact@alex-min.fr>

