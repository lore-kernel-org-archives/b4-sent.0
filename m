From: Han Gao <gaohan@iscas.ac.cn>
Subject: [PATCH 0/2] riscv/clk: sophgo: Fix EFI RTC on Milk-V Pioneer
Date: Sat, 21 Nov 2026 18:38:06 +0800
Message-Id: <20261121-b4-sg2042-efi-rtc-v1-0-19898b8ad497@iscas.ac.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAyF4asgz7UUm9CBq1QdSDDUDGkV06oSy
 t0JMH56ev8GJlnFoG82yPJT03eqoFsD8TWkWVDHamDHdyImDB5tZucZZVLMa0TxY8fMHbWDQP1
 9cl3+Z/PxvGzfsEhcjxCUsgNqcxa+dQAAAA==
X-Change-ID: 20261121-b4-sg2042-efi-rtc-e4d5222513ae
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795257496; l=1142;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=dT/cAMPkqhwiO+NmtZDAeUI+RgA0LLjV2VMwVQoEOVE=;
 b=FC7ThTXl38Ss0fnSg/4mwqUL1JUFP/nRR5YZZ9Bk32T3DV7XgF8zFNlDBS/VV/IdQ2NT1jZvE
 atOl+cn9WM9D1k1MLLRh6y5Gr2yM/TK/lvJwVM1CPf6X/Q5pk/UR3TE
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pioneer firmware can take over the DS1307 on I2C0 and expose it through
EFI runtime services, so Linux uses rtc-efi. I2C0 is then marked
"reserved" in the device tree.

Two things break GetTime() in that setup:

- RISC-V maps EFI runtime MMIO as normal memory, and firmware takes a
  load access fault on the clock controller. Patch 1 maps it as I/O.

- I2C0 shares a clock gate with the other I2C controllers. Once Linux
  runtime-suspends them, the gate goes off and GetTime() returns
  EFI_NOT_READY. Patch 2 keeps gates used by reserved devices on.

Tested on Milk-V Pioneer.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Han Gao (2):
      riscv: efi: Map runtime MMIO with device attributes
      clk: sophgo: sg2042-clkgen: Keep gates of reserved devices enabled

 arch/riscv/kernel/efi.c                |  2 +-
 drivers/clk/sophgo/clk-sg2042-clkgen.c | 38 +++++++++++++++++++++++++++++++++-
 2 files changed, 38 insertions(+), 2 deletions(-)
---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261121-b4-sg2042-efi-rtc-e4d5222513ae

Best regards,
--  
Han Gao <gaohan@iscas.ac.cn>

