From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v2 0/2] media: rockchip: rkcif: various fixes
Date: Fri, 20 Feb 2026 09:15:06 +0100
Message-Id: <20260216-rkcif-fixes-v2-0-ee40931fe0ff@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAoYmGkC/22Nyw7CIBBFf8XM2jGABh8r/8N0wcDUEhEMaKNp+
 u+OXbs8J/cxQeMaucFpNUHlMbZYsoBZr8APLl8ZYxAGo4xVRlusNx977OObG1IIx7D1e96RAmm
 Qa4xUXfaDdPIrJZGPyktazKUTHmJ7lvpZHkf9s//HR40KSdtARpEN9nD2JSVHpbqNL3fo5nn+A
 pQJiWW/AAAA
To: Dan Carpenter <dan.carpenter@linaro.org>, 
 Paul Elder <paul.elder@ideasonboard.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Cc: Collabora Kernel Team <kernel@collabora.com>, stable@kernel.org, 
 linux-media@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Michael Riesch <michael.riesch@collabora.com>, 
 Chen-Yu Tsai <wens@kernel.org>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771575308; l=1152;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=QUFyLFVNFD15SkUE8r9Qz2zM/lufvVEda1scMmLZJpw=;
 b=Npi/LRz/yYZBkJ3+diYHU47zp2Qqf54Rp4LL44ULFxsTXERqUPwiipVtlCo168v/NtIkaVUl2
 dkhVOUoKy1PCWQO+KwWkFVIYLWqPWDUI9/pqo0y7/sfrMEIJNzajgfD
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

This series contains

 1) a re-spin of Dan's patch that fixes some more stupid off-by-one issues.
    This patch has been around on the list for some time, but apparently
    has not been applied yet.
 2) a fix that makes the DMA abstraction respect the minimum number of
    buffers requirement

Best regards,
Michael

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Changes in v2:
- fixed index of second buffer (Paul)
- fixed cosmetic issues (Laurent)
- Link to v1: https://lore.kernel.org/r/20260216-rkcif-fixes-v1-0-b16db20b6d68@collabora.com

---
Dan Carpenter (1):
      media: rockchip: rkcif: fix off by one bugs

Michael Riesch (1):
      media: rockchip: rkcif: comply with minimum number of buffers requirement

 .../platform/rockchip/rkcif/rkcif-capture-mipi.c   | 10 ++---
 .../media/platform/rockchip/rkcif/rkcif-stream.c   | 44 +++++++++++-----------
 2 files changed, 27 insertions(+), 27 deletions(-)
---
base-commit: c824345288d11e269ce41b36c105715bc2286050
change-id: 20260216-rkcif-fixes-bdd9d3c7e4b0

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

