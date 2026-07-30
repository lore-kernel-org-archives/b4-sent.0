From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 31 Jul 2026 01:03:26 +0800
Subject: [PATCH RFC v4 5/7] ipmi: ls2k: Relax the dependency to its mfd
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-ls2kbmc-mod-v4-5-d201502ba239@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1266;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=DqOdU6W3FkZ9wJNJOs/NgLGl94jX8Hgep53VmIhV2nQ=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqa4PkC1n+JQCUPw/g4JCMJcxFmnJHWCouwbX2S
 InWjoi5/TSJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCamuD5AAKCRCwMePKe/7Z
 bt0/D/40bGmWcIXSf8UM3FtduAC4s4VhDqlKqULHrJSJD+LFmzku0K7KbvFdVkVCeIeVH8AnDuO
 XNUpQ9tk5PhBibCI9wDdaxJeb7kJOs+VN8itxzMqKKTscUuQsnPLcpQ1Jkc2JFJnFvhK9/LAW1A
 mmlTzQQhVyxUgXz+XfhMDIwzBLp8aFumClQtpVX/dk1LWiDldwow4gQGah4fAF2cTFBYbz9PjvR
 T62q9Xo6ArCkgHTPyZkdCkD5GqntE1ztJSvP70+oPfzKm569j+x/TLC+laPyYKl4CKP4O2Q5e9i
 KvBssmrTgN72/evt2XuPliKLahJFa8TA7CIX1u8jroQ2O360ckQdJ8MHDGuZGeaojP5UVOK88oG
 tzUhB03csmq/jM7XinTWiE/NRsdoL0ioUvQm7HV8JmsLIVwXV6WOrEt1zAHO3vYde1W5z80zmgo
 E1+3CmOpChkQl6zrQ4g0S/Gy//YX9EoMMu9WeTc3LgH/dK4TNkBW7DN8aFBoaz+CmVq1HZyxABT
 B7Gw+Z5VQB5KkLXYJKhKnjb5z7ThLntvecJBeqNXu0+5armUxz+MuXCcFTwpL3q0g7nTVLHLBUM
 4+gfZsc1VHEtYNKmhsYcjmcsr1vwoOwgtFcn1CWo7520TMK/pKoNuQ7unJhM3kPhqiyPDTjPUzu
 Zi8L8V1THuYGw9Q==
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
module.

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

