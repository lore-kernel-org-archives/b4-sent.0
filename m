From: Sam Day <me@samcday.com>
Date: Tue, 02 Jun 2026 17:18:58 +1000
Subject: [PATCH v2 2/6] armv8: spin_table: add hook for booting cores
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-msm8916-smp-support-v2-2-792e53dac374@samcday.com>
References: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
In-Reply-To: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
To: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Mark Kettenis <mark.kettenis@xs4all.nl>, Sumit Garg <sumit.garg@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 Casey Connolly <casey.connolly@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Kory Maincent <kory.maincent@bootlin.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Sughosh Ganu <sughosh.ganu@arm.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780384740; l=2300;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=t8uheGFiPfRm69fYegUVGyZihoji0eRWhr6Iiux+UJM=;
 b=h2j2FY5v+u6eHjabCrzQsHTugBSivUipxhjnmaPi/ZXDfwfWBag0hyYrR+xQB4NDn9UDCy5la
 MrBCm7q24uRDvM6dTvX7rp1GGkEv+rGlS5yRVw/sdugoaLjXGngEL1N
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce the weak symbol spin_table_boot_cpu, which is called by
spin_table_update_dt during pre-boot FDT fixup phase for each CPU that
has enable-method="spin-table".

This saves the board/arch code from needing to scan the DT looking for
CPUs to boot, and also makes it easier to bring the secondary CPUs online
as late as possible.

Reviewed-by: Tom Rini <trini@konsulko.com>
Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/cpu/armv8/spin_table.c   | 20 ++++++++++++++++++++
 arch/arm/include/asm/spin_table.h |  1 +
 2 files changed, 21 insertions(+)

diff --git a/arch/arm/cpu/armv8/spin_table.c b/arch/arm/cpu/armv8/spin_table.c
index 5ba20efa33b..32bf680f02c 100644
--- a/arch/arm/cpu/armv8/spin_table.c
+++ b/arch/arm/cpu/armv8/spin_table.c
@@ -8,11 +8,18 @@
 #include <linux/libfdt.h>
 #include <asm/spin_table.h>
 
+int __weak spin_table_boot_cpu(void *fdt, int cpu_offset)
+{
+	return 0;
+}
+
 int spin_table_update_dt(void *fdt)
 {
 	int cpus_offset, offset;
 	const char *prop;
+	const void *release_addr;
 	int ret;
+	int found_cpus = 0;
 	unsigned long rsv_addr = (unsigned long)&spin_table_reserve_begin;
 	unsigned long rsv_size = &spin_table_reserve_end -
 						&spin_table_reserve_begin;
@@ -45,12 +52,25 @@ int spin_table_update_dt(void *fdt)
 		if (!prop || strcmp(prop, "cpu"))
 			continue;
 
+		release_addr = fdt_getprop(fdt, offset, "cpu-release-addr", NULL);
+		if (release_addr)
+			continue;
+
+		found_cpus = 1;
+
+		ret = spin_table_boot_cpu(fdt, offset);
+		if (ret)
+			return ret;
+
 		ret = fdt_setprop_u64(fdt, offset, "cpu-release-addr",
 				(unsigned long)&spin_table_cpu_release_addr);
 		if (ret)
 			return -ENOSPC;
 	}
 
+	if (!found_cpus)
+		return 0;
+
 	ret = fdt_add_mem_rsv(fdt, rsv_addr, rsv_size);
 	if (ret)
 		return -ENOSPC;
diff --git a/arch/arm/include/asm/spin_table.h b/arch/arm/include/asm/spin_table.h
index 8fc61237e07..3c422046b83 100644
--- a/arch/arm/include/asm/spin_table.h
+++ b/arch/arm/include/asm/spin_table.h
@@ -10,5 +10,6 @@ extern char spin_table_reserve_begin;
 extern char spin_table_reserve_end;
 
 int spin_table_update_dt(void *fdt);
+int spin_table_boot_cpu(void *fdt, int cpu_offset);
 
 #endif /* __ASM_SPIN_TABLE_H__ */

-- 
2.54.0

