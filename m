From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 03:24:04 +0800
Subject: [PATCH RFC 3/5] mfd: ls2kbmc: redraw using exported functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v1-3-c344bf5defa3@gmail.com>
References: <20260708-ls2kbmc-mod-v1-0-c344bf5defa3@gmail.com>
In-Reply-To: <20260708-ls2kbmc-mod-v1-0-c344bf5defa3@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1128;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=jR0zkTYATeBvEvhlpMfd7NXfkqbc1ADtj28KwRFGZ1I=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTVJcJaqq+A2TyUF8TOlnI6vAnS7PAHy99Vf4+
 ES+82ZNR5mJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1SXAAKCRCwMePKe/7Z
 bk8SD/9M7CSDPMDHQbE17fopofMDLMhD8KP+vRFaPbWvaglMXE5q9BRKWqaHjQmr8WTHueaAth+
 tN1HodUdKdDADX6M+tuZ3Q4ZxP1rXs9ITlVLQM55kpRziBR3kLzxzjElAM4RKLIZCSuJUdMH+5X
 p9sDakn32uz0ppJbtO2eRGTF+csYVlaSviZRAYmEs1Lc/JnFGQfkXSfdR7OU1avrd0pWpZYsHgb
 fqGOeSD2SoVAc2jViXd1ySnQ4dta0yJn0mBOVRZSu/eI8Rb+mEV7IGVKsaOZn15xA/9fNwkT0lx
 mMq95c9G49tg2p0xtnQ89lf2eOGCUc/J051L3zjJCv2vBeYJ3FPNdhZsV80lKTflgslWUPlfiux
 TiFkatqp33AtCOyoSmoSAjHzK3p5gS4n5YTxmYA6+KaPhuzUo82wOQXGqdeKnDGADBeeEcKfxxD
 QtounPy9/h9JdItBYEcWyMhNMVo5aP5bWNaelPWVAFYqD+urjFoltKyTd65JgA42enbTcDq59Kc
 fNAmi9QEvAH35aYbvrg0yfAsNk9EUagr2aUWIoJgjvA3Kx+PnlyDckoYdLnXgd6xganXBEuTtLe
 ftVDHRefqRNS+HoSuhwG8KTDXQGJMnH4Kb+LJBzSFPW4o5ljvsveUbdOZ1g4GmU55pUkcn982zE
 gzwwLhVGVIgqVng==
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
index 39ce5e55ffd6d3a578008dd752b3e8dceec9bd81..4ceae6c70fb27ae2d6a2a92f4f45a376f1cdb699 100644
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

