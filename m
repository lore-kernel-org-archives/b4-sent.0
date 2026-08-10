From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 10 Aug 2026 21:04:26 +0800
Subject: [PATCH RFC v8 3/8] mfd: ls2kbmc: Redraw using exported functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ls2kbmc-mod-v8-3-16e44f7322f4@gmail.com>
References: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
In-Reply-To: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1128;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=R0w0JF+qT6VK1lT/PxMrgYCt2zFDY7MivPLY0o0OME8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecxj86Xe/U1Mg25T70Gbq7ySVD/xA3BsUDC8c
 vGQeX6tyUeJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannMYwAKCRCwMePKe/7Z
 bka1D/0TuM3JU2aDaQzWsx05MrsGZtoMZYpKoRRuk6ijBONraSsRXY15HFScQGyQ/kokesQQg/L
 JJpLMHu5VBO8b8pXjge9bLvIDWIcnhiBH4ATnzBaLKNJWKljKt9USjWyORT7Ho8lEQfhx65bmFQ
 Q+WcLQg2biGXLxLUPPYRhR6RHPYDx9ueh3S0RTmR1YwbWs60kFJ0vdRCfIbFr9tBJ+ATcAMeDjR
 Z5m2qRoC7Ejv18Xwo5G+3Rh6ZSI4yaQS6v6puGaxPvcbeVRvaSPdyy67OHxuw6QLSCdEW7S9CfX
 nLRTdSr3EXePmqGcO9398rpj/bKRW7Qhqs3j3WrX+Fdqe5g1di6//zFgzusjGfGipInpGyP+iws
 l6kEIyhdnFE7qcUr7jGlKxEm6YTEOCfv+LrBW8ckhepSjyPtCUQypo69730j8sEuj7+D2/v7l5Y
 wKL6DH52nRZh0L0Z9UO7AcWEYSJ6J6rO3eevOCHfXF1waW5xMYBBnzG+Bzl4WWNXPCcoFtzI3Go
 GR2MshUTpxEa5/kkl7oKWp7XX7ScK0tFpK/2VxFwjNP1Py1xGr+QSxnu8Zj9EqwSN8Ncq58sV7Z
 i5hSATTkqTA6ottSE63UZrZ1xHJy6vsxfeUPIUP71XFB2V7WECSCfLrXcLMQ0P9Q7lrrpctgvL6
 ZO3zK0WcpGhSd1A==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use update_screen, i.e. redraw_screen() to trigger the redraw of the
current vt.

Fixes: d952bba3fbb5 ("mfd: ls2kbmc: Add Loongson-2K BMC reset function support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/ls2k-bmc-core.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index 434db99ee501be8e18de7258af0f465fc16c0709..06ec8143d8cdbe2c8e5a141020d96c21b37fa699 100644
--- a/drivers/mfd/ls2k-bmc-core.c
+++ b/drivers/mfd/ls2k-bmc-core.c
@@ -25,6 +25,7 @@
 #include <linux/platform_device.h>
 #include <linux/stop_machine.h>
 #include <linux/vt_kern.h>
+#include <linux/console.h>
 
 /* LS2K BMC resources */
 #define LS2K_DISPLAY_RES_START		(SZ_16M + SZ_2M)
@@ -310,7 +311,9 @@ static void ls2k_bmc_events_fn(struct work_struct *work)
 
 	if (IS_ENABLED(CONFIG_VT)) {
 		/* Re-push the display due to previous PCI-E loss. */
-		set_console(vt_move_to_console(MAX_NR_CONSOLES - 1, 1));
+		console_lock();
+		update_screen(vc_cons[fg_console].d);
+		console_unlock();
 	}
 }
 

-- 
2.49.0

