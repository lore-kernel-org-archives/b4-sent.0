From: David Heidelberg <david@ixit.cz>
Date: Sat, 29 Mar 2025 13:10:04 +0100
Subject: [PATCH v2] ARM: multi_v7_defconfig add /proc/config.gz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250329-arm-config_gz-v2-1-f725d331fb5d@ixit.cz>
X-B4-Tracking: v=1; b=H4sIABzj52cC/43OQQ6DIBCF4asY1sXAGFC66j0a0xBBnYXSDMRYj
 XcvmnTf5b94X97Ooif0kd2LnZFfMGKYc8CtYN1o58FzdLkZCFCiAsMtTbwLc4/Da9h47bTSjTL
 WKcPy5k2+x/Xynm3unsLE00je/pRKaAkgBYimlMKArrnkzi7oHrhiKrvtdEaMKdDnurXIU/tz2
 x7H8QV+51ff1QAAAA==
X-Change-ID: 20250329-arm-config_gz-7d656859ad59
To: Russell King <linux@armlinux.org.uk>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1193; i=david@ixit.cz;
 h=from:subject:message-id; bh=CbA+gZnkNtIFncohuGK/3N46iMOwo2R3h73PJJZfyhA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn5+M8TVTU30peaj6GGd1EoPFBWTPo29JY3IH4+
 Jy5GzOK5tOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+fjPAAKCRBgAj/E00kg
 cszhD/0UJegGCFX+OSuIwG70meXkExgC8YlChrr49t9ZKSZMLiaagx4qX2Wk1Y4hP4Rb55PXgTJ
 H8VhUU3ak18CnRDETxJGqJznu4klqIsZqzKyf2Xz+BIvcpg1rAn6HPp9b+F8s62xd9Eum6uxsiJ
 OqR9uuSYHEIPirUR9x2FAZpPTZyl2+F5w5eXHObikoVsAHERzcSv/5vFblMzyIa1kj9eZ26D6hT
 22EhHwY7e7gI3Ll/nJgz4iv4mJi19UaTWGaBBfrF99bqCDIQAZisZOQHUXo/Erx0dp2q/h4bLJN
 274jm8OpYQTyNTIts76z44MFEcjd5cEMCtm2RoSSaOToOaS/7+OBz6+LUBbTZ/5kv/dz4wuKj5a
 1dwVCsc/9llGXa50oJDWay0P9jgxZ5QtgGCG3Lp3F/sj/idgS9RTbu4BxMEaBW1RZup4ucZBDGo
 6qTd0A6qsc/QY2l0Gt62H5AKtJ5TbBDi9zikMEJXl6yct2T0UQz3ONX1umpMCY/OGhDzLWZ0vY6
 1u9h0vVmtfV3uEYwMMhBzqJYcj3+8FWRLF4K2un2G4SVYWtZpwd+8RiDxNBXp0yJylLj0kquegR
 HrOmJePcSOFuVxc5VMqwdRLbV+vEhHG65oau7cheeZj0sgl/BKc+d+UAnaFLrqqAZ9lsbgTjLJG
 wkheOjZsBNxBWYA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While 32-bit ARM isn't that widespread, multi_v7_defconfig is used for
building more generic images, where having access to config can be handy.

arm64 and x86_64 already bundle config.gz, so this is an effort to provide
the same level of comfort with ARMv7 devices.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- IKCONFIG is now module instead of built-in (Greg).
- Link to v1: https://lore.kernel.org/r/20230612210208.109267-1-david@ixit.cz
---
 arch/arm/configs/multi_v7_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/configs/multi_v7_defconfig b/arch/arm/configs/multi_v7_defconfig
index ad037c175fdb0ec8601c9b3607aca0c0e5f3c145..16144a519243daee25fbd339b3250e2ff77928ee 100644
--- a/arch/arm/configs/multi_v7_defconfig
+++ b/arch/arm/configs/multi_v7_defconfig
@@ -1,6 +1,8 @@
 CONFIG_SYSVIPC=y
 CONFIG_NO_HZ_IDLE=y
 CONFIG_HIGH_RES_TIMERS=y
+CONFIG_IKCONFIG=m
+CONFIG_IKCONFIG_PROC=y
 CONFIG_CGROUPS=y
 CONFIG_BLK_DEV_INITRD=y
 CONFIG_EXPERT=y

---
base-commit: e21edb1638e82460f126a6e49bcdd958d452929c
change-id: 20250329-arm-config_gz-7d656859ad59

Best regards,
-- 
David Heidelberg <david@ixit.cz>

