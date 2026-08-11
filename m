From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 11 Aug 2026 16:07:27 +0800
Subject: [PATCH RFC v9 3/8] mfd: ls2kbmc: Redraw using exported functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ls2kbmc-mod-v9-3-4fa9a5584406@gmail.com>
References: <20260811-ls2kbmc-mod-v9-0-4fa9a5584406@gmail.com>
In-Reply-To: <20260811-ls2kbmc-mod-v9-0-4fa9a5584406@gmail.com>
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
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqethM12pwfl0638tVKhDruoxf4RKu7faP4vsqt
 CftP+xnF7SJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanrYTAAKCRCwMePKe/7Z
 bsbJEACv+uHBfrsmOS86sA411iFSex2leZIfSlzqiGLcdzrvuvYfXcpWWXAuwCCaPIkfrWoAd+g
 kQSuXySA84OymZrGSLkBEKcBxViEMrknMU9eHQHvfoVAlGzas0MlWAkg5/7UVNHpCHxj4DgZCEU
 /BcqZBNCLScOd3L5O95HD0yeNrnVPr/YPT0WKtn0KS4PrAKuB4CujZfkGMYzhRrh089B0Ku99Dx
 vHX3c66BAjpq+8r7F3CETCiRdwD6tV9xOrkCucywDknvonvZGtp2Ve8FbN611MG0QCZ97hvFrl/
 ud1468W1n3HdIbiSk2gv7GZO50M8q24xCSXtZuYDEGewRMRstrYw/Muo7bozxHjPm/t525JCRua
 Kr7JTCx5T3tD7zmtjF/QEPX4K++F8DKrN7OjtWLgTpbBBYEh4KblUE/BbaLyrG5oKzGol0XjY7U
 ATbfzSKcrIKIYNz7tGwxAvSJqyzhcWe1AJaJzrGefozLkG+2FGAGmgVc3uEobk4lqOJaD4Fm6lh
 2WGXFwtgYWbgGpDlKxP1VbUsN7QRhRwGCe3uT0xw+9zX0fTUqJlZgwNz48+K9nBlZoHBwtMkDqW
 tOwut53EX4wx1o2qrMRsa9DeaYUBQx6hmoHYexXq1jyg+uPYGzlh2CJKkt9d07wJbTscbdeWwq6
 ieEj73Y76WC0oWw==
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

