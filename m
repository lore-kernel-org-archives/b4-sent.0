From: ymodlin <yogev.modlin@realsenseai.com>
Subject: [PATCH v4 0/2] Since Realsense has been spin-off Intel, the
 comment should be change.
Date: Sun, 26 Oct 2025 18:43:01 +0200
Message-Id: <20251026-fix-uvc-v4-0-610eb1329600@realsenseai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJVP/mgC/23MQQ7CIBCF4asY1o6BmVasK+9hXNBhVBJtDSjRN
 L272E1NdPlgvn9QSWKQpLaLQUXJIYW+K6NaLhSfXXcSCL5shRproxHhGJ7wyAzYkPUtGXYNqXJ
 9i1K+ptL+UPY5pHsfX1M4m8/rbyMbMCAVe01rvbZU76K4S5IuiQsr7q/qU8r4rWnWCBoMN7SpC
 Wvr+b+mb13Nmopu7XFDrA2ys796HMc3WDsT/iABAAA=
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ymodlin <yogev.modlin@realsenseai.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761496986; l=1203;
 i=yogev.modlin@realsenseai.com; s=20251022; h=from:subject:message-id;
 bh=k/7TZI9MaeLcnsEULYSl0PNNFCT1m0p+1qssnCP/zuI=;
 b=I1lFqcUO+oQPu1Wcr4buBhXP1zaLw6fPjt4XLadAL5ILz9hl7m59LqaTOnZAoVdZnD0Bkdfms
 IIYgow0/bvADLJER3Kn3lLPhX7iqk8HUN54h92zhVPBz3INN02bjVnx
X-Developer-Key: i=yogev.modlin@realsenseai.com; a=ed25519;
 pk=V3EENbzJJO6YkqjrHtGmN67ulKS2b5TU7Ze0hVi1G1o=
X-Endpoint-Received: by B4 Relay for yogev.modlin@realsenseai.com/20251022 with auth_id=549
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: ymodlin <yogev.modlin@realsenseai.com>
---
Changes in v4:
- reorder Intel RealSense camera according to vid/pid.
- Link to v3: https://lore.kernel.org/r/20251024-fix-uvc-v3-0-b7f83c012ca7@realsenseai.com

Changes in v3:
- Add metadata support for D436 and D555 cameras.
- Realsense D555 has been released to the market earlier this year.
- Realsense D436 will soon be official it's currenly being supplied to
  beta users.
- Link to v2: https://lore.kernel.org/r/20251023-fix-uvc-v2-0-1c93853257dc@realsenseai.com

Changes in v2:
- Fixed commit message formatting
- Write 'Intel RealSense' for D400 family of depth camera comments
- Link to v1: https://lore.kernel.org/r/20251022-fix-uvc-v1-1-e4cd03606735@realsenseai.com

---
ymodlin (2):
      media: uvcvideo: change comment to 'Intel RealSense'
      media: uvcvideo: Add D436 and D555 cameras metadata support

 drivers/media/usb/uvc/uvc_driver.c | 36 +++++++++++++++++++++++++++---------
 1 file changed, 27 insertions(+), 9 deletions(-)
---
base-commit: 552c50713f273b494ac6c77052032a49bc9255e2
change-id: 20251022-fix-uvc-2937db31ca93

Best regards,
-- 
Yogev Modlin <yogev.modlin@realsenseai.com>

