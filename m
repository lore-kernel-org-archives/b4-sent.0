From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 21 Nov 2026 18:38:07 +0800
Subject: [PATCH 1/2] riscv: efi: Map runtime MMIO with device attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-b4-sg2042-efi-rtc-v1-1-19898b8ad497@iscas.ac.cn>
References: <20261121-b4-sg2042-efi-rtc-v1-0-19898b8ad497@iscas.ac.cn>
In-Reply-To: <20261121-b4-sg2042-efi-rtc-v1-0-19898b8ad497@iscas.ac.cn>
To: Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Atish Patra <atish.patra@linux.dev>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen Wang <chen.wang@linux.dev>, 
 Inochi Amaoto <inochiama@gmail.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-efi@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-clk@vger.kernel.org, sophgo@lists.linux.dev, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795257496; l=1030;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=AXs3CmUyHq0DbOalkM59cymNHEWwCflCrFagmnUXH40=;
 b=+R7iok8HWxtWVdFYvjuL61Ut91D/mbpDWKM53jRhVd4qqn7/sjzLv+Snse+8aZgLqEHJOOeid
 xXeqEtr/y3EDSWZSeiif9VMkcf+BUQn8NS0Qrt/IbRR23abw8rzSlfq
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

EFI_MEMORY_MAPPED_IO regions are mapped with PAGE_KERNEL, so device
registers end up mapped as normal memory.

On Milk-V Pioneer, GetTime() reads the clock controller registers and
faults:

  Oops - load access fault [#1]
  Workqueue: efi_runtime efi_call_rts
  status: 0000000200000120 badaddr: 0000007030012000 cause: 0000000000000005

Use PAGE_KERNEL_IO for these regions.

Fixes: b91540d52a08 ("RISC-V: Add EFI runtime services")
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/kernel/efi.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/riscv/kernel/efi.c b/arch/riscv/kernel/efi.c
index 2d3cc57b4535..11e85d0ebc91 100644
--- a/arch/riscv/kernel/efi.c
+++ b/arch/riscv/kernel/efi.c
@@ -22,7 +22,7 @@ static __init pgprot_t efimem_to_pgprot_map(efi_memory_desc_t *md)
 	u32 type = md->type;
 
 	if (type == EFI_MEMORY_MAPPED_IO)
-		return PAGE_KERNEL;
+		return PAGE_KERNEL_IO;
 
 	/* R-- */
 	if ((attr & (EFI_MEMORY_XP | EFI_MEMORY_RO)) ==

-- 
2.55.0

