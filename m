From: ymodlin <yogev.modlin@realsenseai.com>
Subject: [PATCH v3 0/3] Since Realsense has been spin-off Intel, the
 comment should be change.
Date: Fri, 24 Oct 2025 08:49:45 +0300
Message-Id: <20251024-fix-uvc-v3-0-b7f83c012ca7@realsenseai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHkT+2gC/2WMMQ7CMAxFr1JlxiixSUuZuAdiCI6hkaBFCUSgq
 ncn7QIS47P/e6NKEoMktatGFSWHFIa+AK0qxZ3rLwLBF1ao0RqNCOfwgmdmwJYafyLDriVV1vc
 o5bWUDsfCXUiPIb6XcDbz9b+RDRiQDXtNta4bsvso7pqkT+LCmoebmksZf2362ggaDLe0tYS28
 fxvT9P0AT6nBRXiAAAA
To: Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans de Goede <hansg@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ymodlin <yogev.modlin@realsenseai.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761284988; l=1124;
 i=yogev.modlin@realsenseai.com; s=20251022; h=from:subject:message-id;
 bh=1WfFvzYHcSDCH+B4HhPvJNCEBqTW4nPE8Kyf9KkINlQ=;
 b=1Zx2wW+eD4XJ3ZaGki86OeNxnYyV7T4kL1wmAS3vBtcEI4vsuwSfZ+FJYtfQLDn/5ZAk57JiF
 S6rqnwGByFkAUTVednIvUFZTR2TjS91ZLubkm8LdFa2fEZd5SJMKhpc
X-Developer-Key: i=yogev.modlin@realsenseai.com; a=ed25519;
 pk=V3EENbzJJO6YkqjrHtGmN67ulKS2b5TU7Ze0hVi1G1o=
X-Endpoint-Received: by B4 Relay for yogev.modlin@realsenseai.com/20251022 with auth_id=549
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: ymodlin <yogev.modlin@realsenseai.com>
---
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
Yogev Modlin (1):
      media: uvc: Add D436 and D555 cameras metadata support

ymodlin (2):
      change: drop 'Intel' from RealSense camera comments
      media: uvc: Add RealSense vendor prefix to Intel camera comments

 drivers/media/usb/uvc/uvc_driver.c | 36 +++++++++++++++++++++++++++---------
 1 file changed, 27 insertions(+), 9 deletions(-)
---
base-commit: 552c50713f273b494ac6c77052032a49bc9255e2
change-id: 20251022-fix-uvc-2937db31ca93

Best regards,
-- 
Yogev Modlin <yogev.modlin@realsenseai.com>

