From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH 0/2] media: rockchip: rkcif: various fixes
Date: Mon, 16 Feb 2026 14:49:55 +0100
Message-Id: <20260216-rkcif-fixes-v1-0-b16db20b6d68@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIMgk2kC/x2LywqDQAwAf0VybmDdikV/RXrYR6xBWSVBEcR/b
 /A4w8wFSsKk0FcXCB2svBaD+lVBmkL5EXI2Bu9863zdosyJRxz5JMWYc5ff6UNNdGBHDEoYJZQ
 02VP2ZTG5CT21meF73388YpNjcgAAAA==
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
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771249800; l=962;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=msfTh03NG07ETuEWGU73Tj/AyEz3fvIWOKO1VC6wmzE=;
 b=EzemGU4WwwrerpyJyqtpwSkZEMGm+gNFMXztnVatpUldXQTDeZsDGZ8MxfWnBm7/R1bLPh0hI
 h8+KZIwF77YAolHH+0o2kfeiOq61M+Yi/24IZffM9j2nE7HAw/rB8pd
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
Dan Carpenter (1):
      media: rockchip: rkcif: fix off by one bugs

Michael Riesch (1):
      media: rockchip: rkcif: comply with minimum number of buffers requirement

 .../platform/rockchip/rkcif/rkcif-capture-mipi.c   | 10 +++---
 .../media/platform/rockchip/rkcif/rkcif-stream.c   | 41 +++++++++++-----------
 2 files changed, 26 insertions(+), 25 deletions(-)
---
base-commit: c824345288d11e269ce41b36c105715bc2286050
change-id: 20260216-rkcif-fixes-bdd9d3c7e4b0

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

