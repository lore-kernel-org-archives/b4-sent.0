From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v4 0/2] drm/tegra: Support YVU formats
Date: Sun, 25 Oct 2026 17:34:28 -0500
Message-Id: <20261025-tegra-drm-yvu420-v4-0-30b3bb0d0752@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NwQ6CMAyA4VchOzvTbkOGJ9/DeBjbgCUCZsNFQ
 nh3ByeixuPftF9nEqx3NpBzNhNvowtu6FOIQ0Z0q/rGUmdSEwbshACSjrbxihrf0Sk+BQOKpqo
 KFGBzoUg6e3hbu9dGXm+pWxfGwU/bh4jr9A8WkQI1GrUQXAPU/NJ0yt2PeujIikW2A/AXwBKQI
 5OyROCqEp8A3wFp/xvgCShqLJXkolKl3APLsrwBBeCqZDIBAAA=
X-Change-ID: 20261008-tegra-drm-yvu420-1dbb7140e54a
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792967672; l=2128;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=ilqcffhru43nXGSWBduPO0jtANCxR7RAgDglJEEAKNo=;
 b=Oy9FfeM3IQVzNcWnlSZvuWSffvGe0eSkfXzn1LFrxyqa70g8MAm04jiHAD5TNGUH54pfUnvaU
 aNLPACdL4FeDAIHBcdskrHm1On5iGyOGywkpo3u8w7rUpN3GdfIwE+e
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is not directly supported by the display controller hardware.
However, this can be handled efficiently on tegradc by just passing the
chroma planes to the hardware backwards and reporting it as the yuv
equivalent. Nvdisplay has a hardware flag to handle the swap in
hardware.

YVU420 is required by AOSP for software decoded video playback among
other things. An attempt was made to handle this in gralloc by swapping
the chroma planes there, but it wasn't working. This kernel
implementation is working and is more generic anyways. This has been
verified on a SHIELD TV 2019 Pro for the tegradc path and a Jetson TX2
NX for the nvdisplay path.

---
Changes in v4:
- Drop yvu422 from the nvdisplay path. Yuv422 is not supported and will
  be removed separately
- Link to v3: https://lore.kernel.org/r/20261020-tegra-drm-yvu420-v3-0-7f19a834ba98@gmail.com

Changes in v3:
- In patch 1, use the SWAP_UV window group flag instead of manually
  swapping for nvdisplay
- In patch 2, support the chroma swapped variants of the other yuv types
- Link to v2: https://lore.kernel.org/r/20261018-tegra-drm-yvu420-v2-0-512889103ab4@gmail.com

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
      drm/tegra: Support YVU formats

 drivers/gpu/drm/tegra/dc.c    | 13 ++++++++++++-
 drivers/gpu/drm/tegra/hub.c   |  8 ++++++--
 drivers/gpu/drm/tegra/plane.c | 29 ++++++++++++++++++++++++++++-
 drivers/gpu/drm/tegra/plane.h |  3 ++-
 4 files changed, 48 insertions(+), 5 deletions(-)
---
base-commit: 20a33c6b6cbe7e4805dfb6cd68816937443aa148
change-id: 20261008-tegra-drm-yvu420-1dbb7140e54a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

