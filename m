From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 05:16:27 +0800
Subject: [PATCH RFC v2 3/7] mfd: ls2kbmc: Redraw using exported functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v2-3-2afdd1741766@gmail.com>
References: <20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com>
In-Reply-To: <20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com>
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
 bh=OujIxIWqUrslWQYj9yXk01UV8a8eZbDNcLz7yiDWTA0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTWy1tkwa7idugyOUqAD5VwuWdN5wcCPYEPIEP
 wwwUBkxP+OJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1stQAKCRCwMePKe/7Z
 bqIED/9Oaash6gWJfYJCuYAbOEhtcmw2o9N6Q4MV03SmZ7WbHrpPs5FvNcbt59fFUS/+B90EXfH
 ob5VdgMY5DON/Q1BL5jl++ZA8+NwNgtEj+I8kTZvykdngla5YKYq3YktURfYzYCWk0cV4xYdWrU
 EtleQYyDDFkwPPzqmcIRdswd8kNsh1Nq4AZimc4s7WVpb3LyQa07LkXRhGRD2/HQ+S4yw0U2g9D
 koShv8OAJN0C7Au7ulmFARKfHQgIRWYHcxAyYOfKLnchbCPgLrNhUS9LNW5Hs+fGFCSUm+e5VKk
 5sgvGwQGNI1cxnc1szild48NSyUN7wY/pIfu+FNmU8ARLSqGp7XZByWT8CAhL7Fp9hAWnCK+vdH
 2IomEU3enCInKGkIc2gEXqe8ZO6WuYXE7X9+CaKqWPrhdC+8LLJqVoGog3vAWvVKQBTpWR1YLT3
 Kph+tO0LcSMt+SQfyuOCawsOXV73Qcmq+Jh4/hElYbZ6S8jokWzICDSwPAV1EreX7WaSdvDaaMY
 0cncrdsNF4E42j23Of09aoutRa1QVw/BRXSVE1sUgn/LYEFo59xi8MvRm9QqDKnALim4MIm9H2Q
 oEd5AMv6nAnihtrgFbM8cSBAz/leDiRtOKbwKiFNXNJvyM0khwjbyfAD1XAylnvr5Z9UIhgsN2P
 pd/+4n6UaWeRLrQ==
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
index b02e4955e9b04f517892a18b2ef103b5e481a238..a5465c42a77b8b7b81e3ad787d6036679c6ba6df 100644
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

