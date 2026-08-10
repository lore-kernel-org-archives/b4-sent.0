From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 10 Aug 2026 21:04:28 +0800
Subject: [PATCH RFC v8 5/8] ipmi: ls2k: adjust dependency to its mfd driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ls2kbmc-mod-v8-5-16e44f7322f4@gmail.com>
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
 Miao Wang <shankerwangmiao@gmail.com>, Corey Minyard <cminyard@mvista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1757;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=5F0h5Qv+XPb37y2d1dKKxcFdJW7AFH0K1WRgvpNasK8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecxjtfQTc0QSSDoPPYG18h1L5VleyAgxbEaO8
 5dGidwkSyaJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannMYwAKCRCwMePKe/7Z
 bjmnD/9VIqtDfpNlgtDQejt/nciwHhy4OH14DSLvuuDuyePD7GGv5X4O2kxhODAKF4pHmsMgMpo
 pBivCXRcFUvct2PDYNPT0zM3nU2Gee5Vu8ouWLGcIC0WgnFOuIGMnGgiZDXT48mvDmgWOFzJNE7
 gnEwTMGJ1N+6k7PJdRrRQffBVt4M8hTuS7MHMNx59x1R361t1Yw41PIofI/ljrSHf+4vL1hciIr
 2iFqInO2XfVIrk1E6mF76IrF1lQllzo6fgdwzSeN4L2cqg1jgUySIl/LEf9BvH4TzhBuk4ARofD
 2A+r/l4MoJ0m19m1Wvd3X0irfndgiIFKvM/rCYAsb+UqLlzt8p7XioShcrdJ59+MRXTS24xCYaY
 2ZwoSs1BJNu9DyPRDmJKLDJ/fhFRvqr2ONoUZnvZ1KUCpOb8c9bvCt/qhfnqfL7vIIRV8A7swWm
 7PUIqhKj28FG/0nMsSgrw34jPeYGFNIhsCIdiurDF2s092nYGTzf9cKOtqSOurc3eNEur2d5mBb
 +gqzIkbED7/fBIRwsgT5F0SHNH0iAknTIgxdPIUiFVPR38CE1gUW6LmkS+hw7B2yZ/oOAMu5Vzd
 GtmcUyC+Im+7llbl2vWW9z8dtUYbNpQF2Amkx9wy5SS9U3dtgnSG/pgWhmOyEr8MYBcF/UwIc7K
 afiZYObdvKDvW/A==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is functional dependency between the IPMI driver and its mfd
driver. Previously, the dependency was set to "select" from
IPMI_LS2K to MFD_LS2K_BMC_CORE. However, the ipmi driver is actually
compiled as a part of the ipmi_si module, and IPMI_LS2K is a bool
option. Therefore, the dependency "select" will force the mfd driver
to be compiled built-in when the ipmi driver is built as a module. This
is not desirable. This patch fixes this by declaring a conditional
dependency from IPMI_SI to MFD_LS2K_BMC_CORE if IPMI_LS2K is selected.
This will allow the mfd driver to be compiled as a module if the ipmi
driver is built as a module. The adjustment to Kconfig for the mfd
driver will be introduced in the later patch in this series.

Fixes: d46651d4e3c0 ("ipmi: Add Loongson-2K BMC support")
Acked-by: Corey Minyard <cminyard@mvista.com>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/char/ipmi/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/char/ipmi/Kconfig b/drivers/char/ipmi/Kconfig
index 669f7600019747bcd2b37563477cf336f19a0407..07f3308c71616215871a730b87f1991d2b502e63 100644
--- a/drivers/char/ipmi/Kconfig
+++ b/drivers/char/ipmi/Kconfig
@@ -62,6 +62,7 @@ config IPMI_DEVICE_INTERFACE
 config IPMI_SI
 	tristate 'IPMI System Interface handler'
 	select IPMI_PLAT_DATA
+	select MFD_LS2K_BMC_CORE if IPMI_LS2K
 	help
 	  Provides a driver for System Interfaces (KCS, SMIC, BT).
 	  Currently, only KCS and SMIC are supported.  If
@@ -87,7 +88,6 @@ config IPMI_IPMB
 config IPMI_LS2K
 	bool 'Loongson-2K IPMI interface'
 	depends on LOONGARCH
-	select MFD_LS2K_BMC_CORE
 	help
 	  Provides a driver for Loongson-2K IPMI interfaces.
 

-- 
2.49.0

