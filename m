From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] drm/tegra: Support YVU420
Date: Sun, 18 Oct 2026 17:03:45 -0500
Message-Id: <20261018-tegra-drm-yvu420-v2-0-512889103ab4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NTQ6CMBBGr0Jm7ZhpqT9x5T0Mi9IOMImAabGRk
 N7dygFcvpd879sgchCOcKs2CJwkyjwV0IcK3GCnnlF8YdCkz4roigv3waIPI67pbTSh8m17UYb
 4ZCyU2StwJ589+WgKDxKXOaz7Q1I/+yeWFBJ6p5wxtSPq6ns/Wnke3TxCk3P+ArsvzFmwAAAA
X-Change-ID: 20261008-tegra-drm-yvu420-1dbb7140e54a
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792361027; l=1534;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=R/lIBi5xVRT9GBvuisR5VhE0gQGV119/5xNOWD1DMVs=;
 b=FRC4bjtGu7E6H/zvKW1tazwdCKnbUQd6u7L6Nt632QmVvTijrfpLho+6G4U5I3gD2JV9xSXMF
 nrujb+NNsd1BebpvpBJUSNgYBZUyghEMf9ZURmf4OzA/fxY5KdmSyyr
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is not directly supported by the display controller hardware.
However, this can be handled efficiently by just passing the chroma
planes to the hardware backwards and reporting it as yuv420.

The format is required by AOSP for software decoded video playback among
other things. An attempt was made to handle this in gralloc by swapping
the chroma planes there, but it wasn't working. This kernel
implementation is working and is more generic anyways. This has been
verified on a SHIELD TV 2019 Pro for the tegradc path and a Jetson TX2
NX for the nvdisplay path.

---
Changes in v2:
- In patch 1, simplify pre-nvdisplay path to a swap of the window base
  address
- In patch 1, address sashiko report about failure to copy the new
  struct entry in duplicate_state
- In patch 2, address sashiko report that yvu420 was missing from
  tegra20_overlays when the targets already support yuv420.
- Link to v1: https://lore.kernel.org/r/20261008-tegra-drm-yvu420-v1-0-dc1c443c00f3@gmail.com

---
Aaron Kling (2):
      drm/tegra: Support swapping chroma planes
      drm/tegra: Support YVU420

 drivers/gpu/drm/tegra/dc.c    |  9 ++++++++-
 drivers/gpu/drm/tegra/hub.c   | 15 ++++++++++-----
 drivers/gpu/drm/tegra/plane.c | 13 ++++++++++++-
 drivers/gpu/drm/tegra/plane.h |  3 ++-
 4 files changed, 32 insertions(+), 8 deletions(-)
---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20261008-tegra-drm-yvu420-1dbb7140e54a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

