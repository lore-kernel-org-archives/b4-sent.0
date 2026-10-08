From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] drm/tegra: Support YVU420
Date: Thu, 08 Oct 2026 15:57:20 -0500
Message-Id: <20261008-tegra-drm-yvu420-v1-0-dc1c443c00f3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwML3ZLU9KJE3ZSiXN3KslITIwNdw5SkJHNDE4NUU5NEJaC2gqLUtMw
 KsJHRsbW1AMB0Ij5iAAAA
X-Change-ID: 20261008-tegra-drm-yvu420-1dbb7140e54a
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791493050; l=1112;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=X2R3fkt9RuPxE9JCSn7LtflkpjPza9Wh3xPjFZ5Z2W4=;
 b=A9F57GabAMH26MMYQWQKBrdO32IjHhYRWZ1SjhAhc5gvhOt812wLq3GDzyrlKIm8xNjEb3+LB
 XUrmuNmU+ByAd80p3rZ0BcOTISlPIeyAFsS6ijdxqrp3FR20C11NDPd
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
Aaron Kling (2):
      drm/tegra: Support swapping chroma planes
      drm/tegra: Support YVU420

 drivers/gpu/drm/tegra/dc.c    | 19 ++++++++++++++-----
 drivers/gpu/drm/tegra/hub.c   | 15 ++++++++++-----
 drivers/gpu/drm/tegra/plane.c | 12 +++++++++++-
 drivers/gpu/drm/tegra/plane.h |  3 ++-
 4 files changed, 37 insertions(+), 12 deletions(-)
---
base-commit: aac26bee2287c88af5be5a5ff96d783b19a28790
change-id: 20261008-tegra-drm-yvu420-1dbb7140e54a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

