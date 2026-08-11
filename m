From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 11 Aug 2026 16:07:29 +0800
Subject: [PATCH RFC v9 5/8] ipmi: ls2k: adjust dependency to its mfd driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ls2kbmc-mod-v9-5-4fa9a5584406@gmail.com>
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
 Miao Wang <shankerwangmiao@gmail.com>, Corey Minyard <cminyard@mvista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1757;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=5F0h5Qv+XPb37y2d1dKKxcFdJW7AFH0K1WRgvpNasK8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqethMA6i5911fDr9+W56U17mC736BFcdcliqaR
 WjBcuKyZrWJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanrYTAAKCRCwMePKe/7Z
 btO/EADRS6R487wlLJzhAluSMrXDJaCqHNoNwBnzmvLdT1tebRA1FN0UEAFctgaZPPJ4aonIZER
 KSq/uL12UPkS3RSqlq+eGLgTVU9d0HDEXI4wJWY1waWQels20mP0OUP4IbwfORL7WBWteWlFe+h
 gfMYNCnoCfUXkSrzJNOdf8bJqvr4nAHNYFxWPUTLKyYYT0V4OUvRtQxpPIm8SR2Y+WI7Lj4xU39
 3RsmQ2mbSKPPQjVZm8RUMKcV4eVVANkCBRY692RtMu9acmEDVzhqhdIBcolIPhRMR0TrftMF1vR
 PWLH5eECrn6evnyuoNVByWweTu5o8JiclsAp7IrBfiSF9MeCsGbNedfRzeKnY0oWh7zliFMTicS
 vipar11pGPKGvNrNk7YWryubmX2yGWAnJecQEnXHXph0DIOAi/st+qkYhCB8BuPl365GwKEj9E0
 ddFabpA/kgdCfS9yiF9Nd+XO8eZcAnvZ+emmpUO9G/jKQ9LNN/PWd7OOwbiGzohA63nNg8mRD9H
 FV/fizAPG7jZ2K6Kxj8FTWWtdSfGnL7kfDlxX1MseE5u25yJ4R22G5h//LX4DM+5KjsSSMQOiGY
 Qb83kpCBAKl0/0Ft3M7JZThwYa2jZd9L5UDK/qOfCqNwRw+/kerIvGXikEqW4mgjgMqMo8cWZR9
 QbEBTn4PjiIRncQ==
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

