From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 10 Jul 2026 01:24:22 +0800
Subject: [PATCH RFC v3 6/7] mfd: ls2kbmc: Able to be compiled as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ls2kbmc-mod-v3-6-ef718636e78e@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=4cYoUAWfr6lC2eTeoh29c5JZOLqOi/IiHDJf/iiky6g=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT9la4CJbrSXeiOdx6rKWijSotf1UR0bj6PC4l
 uz6ToNr+TSJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/ZWgAKCRCwMePKe/7Z
 bmhwD/47GGXrGDaz5O7vrcrXTU+qDXUIultuqzdjvPV4LcSfNxHp21AC1XneWDecbOOyHoVvsdy
 a1cVf7Rmkh2Rq5h8wXCby7bDYGb2R9cY2/Ao9jaO0zBHhWX6dGxYw3mc50vGeg7IGowBlZ4OtL9
 iU+aLjfy6NpJP8AqWefP+/8H2iQuWOKgnPne2DfcuQcVG4ToavmRDGM0CseukvIwWIsgFCoIMWV
 l0xEpBLtqe+J1qgqNLHEmJVRdolvh6MMDcO9vXY+mJGbZ0+xy7D0X+GNPNX5W0KgwUW38ALawBC
 bi0gcZb2eAwbCTQldWdQkrQdGZjRoGLgUPUOd83TkBgj/xK2SgTg98h5GPw9h5+9goA7A+Fg7Fc
 9SmdTLaZYSDOE5WZKaS3QSWqxvT9znYRJplS4jBkTMt6BKD3CuBuVORlkg+z4zEEalDqKiIE/+Y
 gxY4K6xAQ4q9PjhgsAf6nzjBsK27/nHAk5ASI3b515lvi08E13J8Xi4iGW6WRETBMaSAFviZ0L6
 4wt32DLNKJY7W83oNovZOmC6Yxl4djFpssD7adyS/t8YGntYCYmdV5i9bv9oSoR+ebvqhTjFoLt
 FrW2atkd41bUfd1ki75n8z1Jeu+f328UwnZISNvOcPEDHhimb4Lu5DFGhgA7WDAa3QuJNVzhWl1
 NCdZrAe4tRJ04ww==
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

