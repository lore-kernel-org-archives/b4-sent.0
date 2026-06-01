From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:45 +1000
Subject: [PATCH RESEND 04/16] mach-snapdragon: qcom_parse_memory 32-bit
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-4-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=2862;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=kQo2M8SlSKYZvJ8hXNOdulomZMDlixNj/rjODXhG9g8=;
 b=mK/QSnAUj7pD1oZAXtCoevdwYT5FPuTd7/qHwBzd2TA1+7uEqMCvFS3t2L8rYOd+hZQG/tl0W
 7k69783JilgAL74zvJTYwaq2VsiQjBjEagPeKieviS330XtMQh+6NH3
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qcom_parse_memory is updated to handle varying address/size cell counts,
rather than assuming a count of 2 (64 bit). This means it can now parse
/memory nodes in both arm64 and arm32 devicetrees.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/mach-snapdragon/board.c | 42 ++++++++++++++++++++++++++--------------
 1 file changed, 28 insertions(+), 14 deletions(-)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 829a0109ac7..56e943058ed 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -115,8 +115,9 @@ int dram_init_banksize(void)
 static int qcom_parse_memory(const void *fdt)
 {
 	int offset;
-	const fdt64_t *memory;
+	const fdt32_t *memory;
 	int memsize;
+	int parent, addr_cells, size_cells, entry_cells;
 	phys_addr_t ram_end = 0;
 	int i, j, banks;
 
@@ -124,33 +125,46 @@ static int qcom_parse_memory(const void *fdt)
 	if (offset < 0)
 		return -ENODATA;
 
+	parent = fdt_parent_offset(fdt, offset);
+	if (parent < 0)
+		return -ENODATA;
+
+	addr_cells = fdt_address_cells(fdt, parent);
+	size_cells = fdt_size_cells(fdt, parent);
+	entry_cells = addr_cells + size_cells;
+	if (addr_cells <= 0 || size_cells <= 0)
+		return -ENODATA;
+
 	memory = fdt_getprop(fdt, offset, "reg", &memsize);
 	if (!memory)
 		return -ENODATA;
 
-	banks = min(memsize / (2 * sizeof(u64)), (ulong)CONFIG_NR_DRAM_BANKS);
-
-	if (memsize / sizeof(u64) > CONFIG_NR_DRAM_BANKS * 2)
-		log_err("Provided more than the max of %d memory banks\n", CONFIG_NR_DRAM_BANKS);
+	banks = min(memsize / (entry_cells * (int)sizeof(fdt32_t)),
+		    (int)CONFIG_NR_DRAM_BANKS);
 
 	if (banks > CONFIG_NR_DRAM_BANKS)
 		log_err("Provided more memory banks than we can handle\n");
 
-	for (i = 0, j = 0; i < banks * 2; i += 2, j++) {
-		prevbl_ddr_banks[j].start = get_unaligned_be64(&memory[i]);
-		prevbl_ddr_banks[j].size = get_unaligned_be64(&memory[i + 1]);
-		if (!prevbl_ddr_banks[j].size) {
-			j--;
+	for (i = 0, j = 0; i < banks; i++) {
+		phys_addr_t start = fdt_read_number(memory, addr_cells);
+		phys_size_t size = fdt_read_number(memory + addr_cells,
+						   size_cells);
+
+		memory += entry_cells;
+		if (!size)
 			continue;
-		}
-		ram_end = max(ram_end, prevbl_ddr_banks[j].start + prevbl_ddr_banks[j].size);
+
+		prevbl_ddr_banks[j].start = start;
+		prevbl_ddr_banks[j].size = size;
+		ram_end = max(ram_end, start + size);
+		j++;
 	}
 
-	if (!banks || !prevbl_ddr_banks[0].size)
+	if (!j)
 		return -ENODATA;
 
 	/* Sort our RAM banks -_- */
-	qsort(prevbl_ddr_banks, banks, sizeof(prevbl_ddr_banks[0]), ddr_bank_cmp);
+	qsort(prevbl_ddr_banks, j, sizeof(prevbl_ddr_banks[0]), ddr_bank_cmp);
 
 	gd->ram_base = prevbl_ddr_banks[0].start;
 	gd->ram_size = ram_end - gd->ram_base;

-- 
2.54.0

