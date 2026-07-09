From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 10 Jul 2026 01:24:19 +0800
Subject: [PATCH RFC v3 3/7] mfd: ls2kbmc: Redraw using exported functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ls2kbmc-mod-v3-3-ef718636e78e@gmail.com>
References: <20260710-ls2kbmc-mod-v3-0-ef718636e78e@gmail.com>
In-Reply-To: <20260710-ls2kbmc-mod-v3-0-ef718636e78e@gmail.com>
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
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT9laS7rZjrVGRXVB+fmOUzlKL6aydQdsIqg97
 Jv/CvpO2WCJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/ZWgAKCRCwMePKe/7Z
 bokXEACZIyWVsNdxahozVJUXJON3N1imfdQ393IkB2/oJIWEFzMscSRCzDAYMg4CFKKl/2PjbHY
 veUOuOVVSjJNaqVM4j3vFr1lYzFjZS2rugCOfrBH2fW07XjjKoMmc3bRrk5Dix/0s3n1OAf2lUo
 sNTOnhfKLxCbLmju6hzjd0NolojyqMGYiNbazRDpy8NinszZCBgyumqqFsfiz6ThHpWw3iOyKTs
 ugAt2A0PKUhQQqbSU+fxMe/tCpaEJlETzV3S6ocX593qD0Ubwyb171boQ9AnyUJX4QHA05eCorw
 VAyBizWmlrM/aUjVTbcPrvwt5n5gQsLixKZI/kaJwlRHfKnKtDjfYJDuZtSovo83EP89PEvYLsG
 nQzz3TP6i0dE8+6hKteH3D52h4kwb2uo7gDlOW0+gx9CPfW4H+gmMSpLGRm0MC0a2z9L/6LDuWJ
 lk8YuwfzSamc1ioJJY5IFz1G+6JCw5BTTH8O+RmJ/OVmafFCL5e23Hf1xMG6CzpW/5jLV2MqTZ9
 yiOvgJfkWMuUqiaBGWOCudrYoJlGO4vcqSj4TU0BIE8VYc74tTgdYvLh0EkkdJ+vgF25TKU/yI8
 M+AH9Fw51STcBsKgjYS8MZ+2tiYikjkwX2zasP86sOGJqRf0Z6SuYtqpeSv29kvAgInoxaSDj6M
 WKOSBOToZRaqnDA==
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

