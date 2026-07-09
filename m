From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 10 Jul 2026 01:24:21 +0800
Subject: [PATCH RFC v3 5/7] ipmi: ls2k: Relax the dependency to its mfd
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ls2kbmc-mod-v3-5-ef718636e78e@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1266;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=DqOdU6W3FkZ9wJNJOs/NgLGl94jX8Hgep53VmIhV2nQ=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT9laVpLfK6V/x0Vbe6h8iLQEGWKb5mPZ/H2oM
 2hM1IPKnzeJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/ZWgAKCRCwMePKe/7Z
 bjX6D/92DGwclTpn8JEIqWvvqivT/xsqa59lGjX8RgaQtQgAieCsMOp+NDj1uaGbrtKeEG7XJv4
 u7AVCPaNIaBRUHu8XwmgLKQbJ5qVaoU96lS2XgQJPY/wlZfjkZDJwoWGz4e7lUtcwK454PlvIXp
 VW2D+TApygU86FNUU4ov6hhuSsz1tr/BSw4hX5PGRNFcBzZUP7eCFeYlyUuwIKQvVpYqKcx8ACc
 QIvfpJdh2lzDjtDeT38UlK4cBlUGU6hKAYDeoyWCQrkNZOUhFIS6CVPCD2stTCGAmKMi2lwT5Wa
 CpyU6cBm3SMR0CpMXvkdWPMwLqwup9CPVRHKizQJcO5yxT0vLZaaGGVl9QxnItxZvAIQmkGbRZd
 InvGttxmzRAx+Nx9XIdVQ79gKAcucKnXqVrXagEZ0P/ZsLpOt4wDhAg+ogSN/aA+keh1dGWdFOX
 HqTFhQILIiMvYCcMQoFKpOnWBbsjbHf0yQ8HGE2FCFuL6kAU5XSSQa1wQo/N+qJ4aIvSoRl99iX
 QAP2ULVzMuhzIiDJcoKpUJ5h2JomZ/H696tXwZjGwf0s/HEFJZrM01DbsVl7Mbv89vGbW4oKesy
 Sy5p9OeFKfEnHTRxbQLB9dk0b5uk3Tg5httLDmhN9EAqHOvoHqZ1DSyaakCNiIJqK5N5xEe+TF8
 kI9rrTkwPVTBv3A==
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

