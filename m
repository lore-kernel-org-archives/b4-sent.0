From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 31 Jul 2026 01:03:27 +0800
Subject: [PATCH RFC v4 6/7] mfd: ls2kbmc: Able to be compiled as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-ls2kbmc-mod-v4-6-d201502ba239@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=4cYoUAWfr6lC2eTeoh29c5JZOLqOi/IiHDJf/iiky6g=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqa4PkPA7Wc+GA/AWysPzTopCQ/u799JcW50iAE
 gYHP7WFcDiJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCamuD5AAKCRCwMePKe/7Z
 bmTJD/9b2FHYtuxq3H2vctryvHH3u9rTvMlDfbcBCjy/IFkpW11r2S3GVggbpfPveYRJVnbOQPm
 XVq0y3d071BzuzurxvLa820eQw6oCum2KBlzCh9HhkYs2SXP6MzeivAD4LITG1cbMhTYlskF10R
 55UoTKMKu+u6umyBiTwjyJcp8K3yvtvg7t3PAbx8MD97Bu1q3FDFFGMvsAaApuC62ZmoqxRlz6e
 YviyPmLfwQNRL0uiu87jtLbFsakW8CQGDWNOj8HqLeJgodleJWfHqJlnxdHqhLwZSQegbXABhbs
 V4C7/eMCP3RI9wdUwMO6fpGDVmoBQPVF+6fiZaeqh8r+s2h0Q+HjaF10zmVRISq7XMiopZgVihg
 oU2itVZEl6HNEZcTOsgD5VpsEavw/15VoUxfo3bPprIGzjqrIi8Qd6egoe+9JaZefD3+lOLQosj
 KBKUv2gPc84DO/DOHk5AGjpX5sQk8eqOWTZbWiyHdBhhdfpAZgN1LC95ioqosR+IQtzdV0xIE5K
 29gFhpbXseggkxzyFbD7lOn7D6x2Kb4Z3vke2QD0sAre8fVLNuIwc6lxXM04vFBCJgMxVnMuvLq
 Pkr2ot9237tz/BKZBBLF4blj56MtgzltbrBkd5TD93/UfoeHo5i2SUD4POPvVbu1/78ar3HCJId
 8S0DGe5wW6dxWfQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make ls2kmc able to be compiled as a module

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/mfd/Kconfig b/drivers/mfd/Kconfig
index 763ce6a34782bdd5d2b1a4d840c75b040092d83e..a7a9f97af248c88489dc1203a1ba05f2ce4827df 100644
--- a/drivers/mfd/Kconfig
+++ b/drivers/mfd/Kconfig
@@ -2494,7 +2494,7 @@ config MFD_LOONGSON_SE
 	  which will forward them to the corresponding engine.
 
 config MFD_LS2K_BMC_CORE
-	bool "Loongson-2K Board Management Controller Support"
+	tristate "Loongson-2K Board Management Controller Support"
 	depends on PCI && ACPI_GENERIC_GSI
 	select MFD_CORE
 	help

-- 
2.49.0

