From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 04 Aug 2026 00:55:53 +0800
Subject: [PATCH RFC v5 5/7] ipmi: ls2k: Relax the dependency to its mfd
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-ls2kbmc-mod-v5-5-e6bc5cdd9a93@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1366;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=gWOO98z6lpPREnTgNizoggde9a0/OsZs516s8lw5YNI=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcMhKLjA7Pw71S5bqO8V/3cOJ+RNzMUIsZ1+R4
 faly8Er4oCJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanDISgAKCRCwMePKe/7Z
 bjU3D/9zO9GKSVabQGWvriUD7pAikHYnLgNvakZ0ZsA22rBP+B9nuItLx/F0gZuM4/GtWsRbObj
 dEdZgNjAcK8uJeyOIu69C71A/iVcRDGuzPpB7pICy/gSYn5I2ZA/+9McNDnsTE7femZikHHjt1X
 wJmg0EdzCSWz2MwVv+9KhwCxSbToMv+6X6Ae3I1B9WkU8gqwSsi2z5y10LsKCcpnzYtmvx1IPK9
 Vqm7ofvXaGOC3FXZAGQN2B73VAoa2905VJ/FNntOQy6WVx1j/Lp7Rlz5BImSJpqbDYix4lJLwcp
 KVUBkRIYDFPExT72Gf1MeqOrqXv46xwnjwN13Dk/APApNqHLrlRGbwSjsRFcW3DVSzOh21c6LFC
 mVrQE9D6WhZqQjathlGvtwuiXsQO4tqoiYVGwkMehYelsgD444oCJ9hOBI0Z6GOWvQhnJIYgbqI
 FhVsG/RVh7EdDk+StY74HJIi+j/0y/Yl8cIbrjtM8pP0AZfiEND8+9ge/LKvOMJddJsPQ/wjciC
 cK3UWyUtGMFMVdfXXZUN7Hdf8c9mYmxXuD9lJckVSPxZxlFlFF4SM2xWom0kM236KcZAF0uBg/l
 m+ZYoyvIf2L5ZWDDbbo+UnLt5c1sCTrLBcZPKX5qYdhyUu5/4ZcVhKlH3IEIOJj0FX4pvzyvhbD
 GJIutlcIHZ7hh5w==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no strong dependency between the IPMI driver and its mfd
driver. Although the IPMI driver will not work without the mfd driver,
it is not a hard dependency. The IPMI driver can actually be compiled
without the mfd driver, and it will just fail to probe. When the mfd
driver is loaded, the IPMI driver will probe successfully. Therefore,
the dependency of the IPMI driver on its mfd driver should be relaxed
to "imply" from "select". This will allow the mfd driver to be compiled
as a module and the IPMI driver to be compiled as a part of the ipmi_si
module. The adjustment to Kconfig for the mfd driver will be introduced
in the later patch in this series.

Fixes: d46651d4e3c0 ("ipmi: Add Loongson-2K BMC support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/char/ipmi/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/char/ipmi/Kconfig b/drivers/char/ipmi/Kconfig
index 669f7600019747bcd2b37563477cf336f19a0407..f456e3e89416932f0d21bb742153a503aeb24267 100644
--- a/drivers/char/ipmi/Kconfig
+++ b/drivers/char/ipmi/Kconfig
@@ -87,7 +87,7 @@ config IPMI_IPMB
 config IPMI_LS2K
 	bool 'Loongson-2K IPMI interface'
 	depends on LOONGARCH
-	select MFD_LS2K_BMC_CORE
+	imply MFD_LS2K_BMC_CORE
 	help
 	  Provides a driver for Loongson-2K IPMI interfaces.
 

-- 
2.49.0

