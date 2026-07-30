From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 31 Jul 2026 01:03:24 +0800
Subject: [PATCH RFC v4 3/7] mfd: ls2kbmc: Redraw using exported functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-ls2kbmc-mod-v4-3-d201502ba239@gmail.com>
References: <20260731-ls2kbmc-mod-v4-0-d201502ba239@gmail.com>
In-Reply-To: <20260731-ls2kbmc-mod-v4-0-d201502ba239@gmail.com>
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
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqa4PjZ5TY7eU5LY1Gegz6rxj1FcLzpdGRJTqha
 SxQvRkLSkeJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCamuD4wAKCRCwMePKe/7Z
 bp09D/0RdR5MCJ/L0JEC855t1lV9x+52iXCZexmWODBvoWEgDiXoW4AuBscULedszTzPK2pMFW7
 d1KXBpson6dyQFG7ugfpueaMKCGSvVJaTHEpIlFmXtb9kKJ7Y/rc4GLDt6fSSzvbQgW6O6WBzva
 ugBYoAeblvRqlt0RFQ30SeUbsZ/d0aXyfbKmig/9AVjXMeQTFNGFqgRceDPa/HAGnqqVwG5slfS
 65U49e6nQ9uVpnw2ZwVv9KGt73xj9OejlFdNlHImMc4QcqwoTawfi5hMGzo0AmzFVGQ0IldfRoN
 T6LGVyeVgbtUC3wNxWp4OtEkT8l9hXzPOhhBJBZKJvwOPl9RebEbcaLYt5nUZ/S5etdLZxMmzyT
 dXDs+wzFASuPZkmqjNPtMJUFtAIaXlJP4B0Q9Vja7aQgB/ZHa/RQqPoXH65xasE/4outOA5vyuU
 kVOEVy9HXzTCXJvbvtvMavqf5j2lbGHJgG707BxYhYD+EThxUPv1n9WwQmS+LZx5PUbRMNd/R5B
 E0Y3qe+9SNcXkn9gWO/njc3FIeJQBcTpVzxZGiWbPXZM4D4YNhl85b6Whrj8iP5excNfI2rzDDe
 MYxrTJ9wc5lwU+2ikfjacWb9b9RJ5xjKc+0HmBVHEDLmDZ5te08V9LyCUN/+a/NR1a4Nm/zTuSs
 uxKEE5q/omWNhGA==
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

