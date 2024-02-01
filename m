From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Feb 2024 22:05:43 +0800
Subject: [PATCH v2 2/3] mmc: dw_mmc: Don't return error if data busy
 timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240201-mmc-v2-2-9f09dc1335fd@outlook.com>
References: <20240201-mmc-v2-0-9f09dc1335fd@outlook.com>
In-Reply-To: <20240201-mmc-v2-0-9f09dc1335fd@outlook.com>
To: Peng Fan <peng.fan@nxp.com>, Jaehoon Chung <jh80.chung@samsung.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706796342; l=966;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=7I6x1oiNonfhfkY+33Aj1D+ocpUIR/g2QtbazCaveps=;
 b=lPdzazMTK3SbqyId2a6GgZSKuF1bkKJqIsnavlmh4ntQjGooNlkQgJmdTwn9yQcOO94ETSFuu
 46uwv+nYnnoCn4q3qxZyVfAZnXzuKW5pYQaIvJDZSapgLrm4BqGLZ8j
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As described in [1], some poor hardware or cards would fail to release
the bus and keep driving data lines low. Ignore it and send the next cmd
directly seems okay for most cases.

[1]: https://patchwork.kernel.org/project/linux-mmc/patch/1424458179-5456-1-git-send-email-dianders@chromium.org/

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/mmc/dw_mmc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/mmc/dw_mmc.c b/drivers/mmc/dw_mmc.c
index 400066fa99..e103664145 100644
--- a/drivers/mmc/dw_mmc.c
+++ b/drivers/mmc/dw_mmc.c
@@ -262,8 +262,8 @@ static int dwmci_send_cmd(struct mmc *mmc, struct mmc_cmd *cmd,
 
 	while (dwmci_readl(host, DWMCI_STATUS) & DWMCI_BUSY) {
 		if (get_timer(start) > timeout) {
-			debug("%s: Timeout on data busy\n", __func__);
-			return -ETIMEDOUT;
+			debug("%s: Timeout on data busy, continue anyway\n", __func__);
+			break;
 		}
 	}
 

-- 
2.43.0

