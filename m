From: ymodlin <yogev.modlin@realsenseai.com>
Subject: [PATCH v2 0/2] Since Realsense has been spin-off Intel, the
 comment should be change.
Date: Thu, 23 Oct 2025 22:24:13 +0300
Message-Id: <20251023-fix-uvc-v2-0-1c93853257dc@realsenseai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN2A+mgC/2WMQQ7CIBBFr9LMWgwMtk1deQ/TBcJoJ1HaMEo0D
 XcXu3X5/n95KwglJoFjs0KizMJzrIC7Bvzk4o0Uh8qAGlujEdWV3+qVvcLB9uFijXeDhWovieq
 1lc5j5YnlOafPFs7mt/43slFG0cEHbTvd9bY9JXJ3oSjkeO/nB4yllC8YFGhnpAAAAA==
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ymodlin <yogev.modlin@realsenseai.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761247458; l=705;
 i=yogev.modlin@realsenseai.com; s=20251022; h=from:subject:message-id;
 bh=gbR+ILxy7ngx0bQKjqtcEIog8d3NC2/uBdxDrlmQj6M=;
 b=/hf5jMg/w6jaMNNETzqPUwiKuWXEwpw9vekIIFCUmHvdjMvoEnqliu92PUWPUTEsDRzA2LAw9
 KjMSpGmePWwBLXre28crbiACLIpRgYgEeleRNTXhhqQpyV5D76cjBFt
X-Developer-Key: i=yogev.modlin@realsenseai.com; a=ed25519;
 pk=V3EENbzJJO6YkqjrHtGmN67ulKS2b5TU7Ze0hVi1G1o=
X-Endpoint-Received: by B4 Relay for yogev.modlin@realsenseai.com/20251022 with auth_id=549
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: ymodlin <yogev.modlin@realsenseai.com>
---
Changes in v2:
- Fixed commit message formatting
- Write 'Intel RealSense' for D400 family of depth camera comments
- Link to v1: https://lore.kernel.org/r/20251022-fix-uvc-v1-1-e4cd03606735@realsenseai.com

---
ymodlin (2):
      change: drop 'Intel' from RealSense camera comments
      media: uvc: Add RealSense vendor prefix to Intel camera comments

 drivers/media/usb/uvc/uvc_driver.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)
---
base-commit: 552c50713f273b494ac6c77052032a49bc9255e2
change-id: 20251022-fix-uvc-2937db31ca93

Best regards,
-- 
Yogev Modlin <yogev.modlin@realsenseai.com>

