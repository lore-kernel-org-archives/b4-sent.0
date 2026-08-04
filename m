From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 05 Aug 2026 03:14:23 +0800
Subject: [PATCH RFC v6 5/7] ipmi: ls2k: adjust dependency to its mfd driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-ls2kbmc-mod-v6-5-16ccde412d86@gmail.com>
References: <20260805-ls2kbmc-mod-v6-0-16ccde412d86@gmail.com>
In-Reply-To: <20260805-ls2kbmc-mod-v6-0-16ccde412d86@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1710;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=fpiTDlsJul0/E2sbRt8CcUmthxoiG2abu6bbCUuF/C8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcjoX2yPyf6ZbALvv192CCQyy3/z+CEEqZfCKm
 5Zp0IRGOUaJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanI6FwAKCRCwMePKe/7Z
 biu5EACpbxNgd9sAvkg/GzaEPsa9a9fh167AxBEYBKD6xmWYr0DyPLhTXCAwwEvYCLSIqvmQkm3
 9sYQIukasRGtEo1ysLM640QrtlVgYBGqOJuIS6Z4keFdXAM2Q2yRBLLOJqR7/dDBD3q/0hNvtPQ
 RR8w8XwNairhTiZNjuxityIFXZGjgwsRvEjuMvPkAxCANngacnQ10owkH7C4niBMaYXvEDcn6MX
 o6wNxUUYTFsqMs+SaPXp7xWH7xQfvCrTwepCpYln3pTKjKZBK0EB3KGYufGqnLEKWL42Qq2hKQa
 X9aMxefe6chaa/YVvoVdyw8z/BBCzTK0VJS+POikvTpOzckk35MW2D37nGeT2XYfe1Al9vdtdnO
 40CsCDvIJvo1HY9pif9XM54vqjf+nNDynA2yWJUttp7/hfDtbhU9xwh12C5d4ZK2eY3DUtPAsH6
 YarwYVT0MaOQMWUfzgXgWDqLXyU9rgxTGMngExmAL9R5+ZlhiqpwpdzWJ7Dyh1+9HtBlrZf907c
 5uBpkR+yLUJlY/ZLovJblcejB4/P7EI6dvuGxG/LmY0+PxJvmvLnQs3JZUntSX0OtH1sdMj4MtK
 wOetI2g9P5C+bejiBV48QzO5bAjVcPvt4cJvaySSMCSSbk3QaGBdz9lpWwsdOWEurCujBBQtL9o
 yy3KcOTDMbAhhng==
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

