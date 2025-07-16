From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 16 Jul 2025 19:25:15 +0800
Subject: [PATCH v3 6/9] MIPS: loongson: Add built-in DTB support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250716-loongson1-arch-v3-6-d160974d696b@gmail.com>
References: <20250716-loongson1-arch-v3-0-d160974d696b@gmail.com>
In-Reply-To: <20250716-loongson1-arch-v3-0-d160974d696b@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752665136; l=1673;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=31SQDWI+tNppoJhNVuSV6AMxuxSd2DNTM292TR9KcKg=;
 b=L+LoNxrEHQl2Mx+K+EVi55An15Kt4JUfoUjnUxlLuX2OLJMHqpJ61OBLIkj4O8uqrNDnvVUGa
 s7m4DrreF/bAw+lOUx3wM7mh26FovUCvITkzkdAqWLcVeFbTiYG4T3t
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the current bootloader for Loongson-1 does not support FDT,
introduce CONFIG_BUILTIN_DTB_NAME to enable a built-in DTB.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 arch/mips/boot/dts/loongson/Makefile | 5 +++++
 arch/mips/loongson32/Kconfig         | 8 ++++++++
 2 files changed, 13 insertions(+)

diff --git a/arch/mips/boot/dts/loongson/Makefile b/arch/mips/boot/dts/loongson/Makefile
index e8f76e7ac303..8ee12504d353 100644
--- a/arch/mips/boot/dts/loongson/Makefile
+++ b/arch/mips/boot/dts/loongson/Makefile
@@ -1,4 +1,8 @@
 # SPDX-License-Identifier: GPL-2.0
+
+ifneq ($(CONFIG_BUILTIN_DTB_NAME),)
+dtb-y	:= $(addsuffix .dtb, $(CONFIG_BUILTIN_DTB_NAME))
+else
 dtb-$(CONFIG_MACH_LOONGSON64)	+= loongson64_2core_2k1000.dtb
 dtb-$(CONFIG_MACH_LOONGSON64)	+= loongson64c_4core_ls7a.dtb
 dtb-$(CONFIG_MACH_LOONGSON64)	+= loongson64c_4core_rs780e.dtb
@@ -10,3 +14,4 @@ dtb-$(CONFIG_MACH_LOONGSON32)	+= cq-t300b.dtb
 dtb-$(CONFIG_MACH_LOONGSON32)	+= ls1b-demo.dtb
 dtb-$(CONFIG_MACH_LOONGSON32)	+= lsgz_1b_dev.dtb
 dtb-$(CONFIG_MACH_LOONGSON32)	+= smartloong-1c.dtb
+endif
diff --git a/arch/mips/loongson32/Kconfig b/arch/mips/loongson32/Kconfig
index a7c500959577..52e925309f15 100644
--- a/arch/mips/loongson32/Kconfig
+++ b/arch/mips/loongson32/Kconfig
@@ -36,3 +36,11 @@ config LOONGSON1_LS1C
 endchoice
 
 endif # MACH_LOONGSON32
+
+config BUILTIN_DTB_NAME
+	string "Source file for built-in DTB"
+	depends on BUILTIN_DTB
+	help
+	  Base name (without suffix, relative to arch/mips/boot/dts/loongson)
+	  for the DTS file that will be used to produce the DTB linked into
+	  the kernel.

-- 
2.43.0

