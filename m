From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 04 Aug 2026 00:55:51 +0800
Subject: [PATCH RFC v5 3/7] mfd: ls2kbmc: Redraw using exported functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-ls2kbmc-mod-v5-3-e6bc5cdd9a93@gmail.com>
References: <20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com>
In-Reply-To: <20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com>
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
 bh=VcxGUAsZn+03JiICVZ3kCtaItmQKTSKAeZBuv6zGY/o=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcMhKrq6jiI7RrNX9FagV9tUCFSss1tfMqJ2th
 qvNYsk/hiOJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanDISgAKCRCwMePKe/7Z
 btk8D/41YbebAtDb2E9S3BwoDh7Yx4FtCVdTo96K6VUzWGIIz/T9s/XZWHdTba2p9e7lKJO+ho7
 Sjy+JA2UFfzpmd3d/SXBbN5cEXOvFmZ9CIuLlK7pgIL83XnY+jACqNdHk7W8QukXXFTEPkdty4Q
 Hhm9QEjt/X7uQZtjunOypbvEVWp8blBwDsLvC65nFUNIPvUF3m3nIgrXcokm2tUo8gUJkc06f6V
 T9onIK7QCGt8e32eHa4zERSagpy7Wq6lyZ02pEPgl4PbT3SLI844D3O8FZsE+6Jgf8KfQJ/6Qgd
 aGZgJ8/KEdKWiBEFBuPhBz7oQ+ffmMfxkGl7nIWE1ukfKNOF7xbceY9hRVamglLOwmczybYfb72
 8fEr4+EYDM8z9rUuDYJPXYFb0HzCzSGpYPk+qDmjs/o+cdm2bP5jwLzKU3GDtYmyYtXaeu8WNvY
 sFAHd1hgvD6mt/ShRpZHWAynqVA7LkIeDJjriacOTGzH4Dx72Y6a5y3GF8g6pJuG7DgxefjutSy
 GMdqSmRjiThq1pX+fECTt8Kk0HHdr468nKx6fUDkTGdT17fs6OSw3RJSV4pSwXdJMTdzwZsi0uq
 Njq52h+pWj/rN1ghPr9UYrsYHkrYgejKbDxOZ6JQb2KKNs1nb6KWEn5286D9XKetkO/+fUJVp4J
 Ft5TEn+Tx/jsOag==
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
index a9a30611dde9e31cd86ff67b1d6e02bf67b34755..e12f2ca2fbef360ceda14ee6fc64f500e4944120 100644
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

