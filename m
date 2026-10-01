From: Austin <austin.schlegel@arthrex.com>
Subject: [PATCH 0/2] serial: tegra: fix RX/TX DMA descriptor use-after-free
Date: Thu, 01 Oct 2026 15:04:00 -0400
Message-Id: <20261001-tty-linus-v1-0-ecb8576c802d@arthrex.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwND3ZKSSt2czLzSYt3EVEuDtGQzEyMz0xQloPqCotS0zAqwWdGxtbU
 AWKl+6FsAAAA=
X-Change-ID: 20261001-tty-linus-ae90fc64265d
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Austin <austin.schlegel@arthrex.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790881447; l=2014;
 i=austin.schlegel@arthrex.com; s=20261001; h=from:subject:message-id;
 bh=nu58vtSvUFtVj0def8uNAfaQ+uA23d3NYZGZbgH3CY4=;
 b=8smowaQK42MKFK9oqcmXIZpFA6hpDFf1vZDYNC+BzjWTgmOGY5fdhRYoUif6O4quRKLssCLEm
 QuUT55D1PYpC7VwD/bfHEtrGOvCe6ayYJ9m5i/OYloOE95mX3ECT59e
X-Developer-Key: i=austin.schlegel@arthrex.com; a=ed25519;
 pk=IGtNH5dFuS24wm8/+OsmhjREhHB9V7zR8eOgh3sZo3s=
X-Endpoint-Received: by B4 Relay for austin.schlegel@arthrex.com/20261001 with auth_id=1096
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both patches in this series fix the same bug pattern in
drivers/tty/serial/serial-tegra.c: dmaengine_terminate_all() is called
before async_tx_ack() on the DMA descriptor it just terminated. With
the GPC DMA driver (tegra186-gpc-dma.c, used on Tegra194/Tegra234),
terminating a channel frees the active descriptor synchronously via
vchan_dma_desc_free_list(), so the subsequent ack touches freed
memory. dmaengine clients are not allowed to touch a descriptor once
it has been terminated.

Patch 1/2 (RX) was found via a KFENCE use-after-free report on a
Jetson AGX Orin (Tegra234) under UART loopback traffic, and the fix
has since been soak tested for 24+ hours with
kfence.sample_interval=1 with zero further reports.

Patch 2/2 (TX) is the same ordering bug in the analogous TX path
(tegra_uart_stop_tx()), found by code inspection once the RX bug was
understood. It has not been reproduced on hardware - triggering it
requires stopping an in-flight TX DMA transfer at the right moment,
which did not occur during RX testing - but it is the identical
dmaengine_terminate_all()-then-ack pattern in the same driver against
the same DMA engine, so I'm sending it alongside the RX fix rather
than leaving it unfixed.

Both patches keep the pre-existing descriptor-leak fix from commit
b31245b94207 ("serial: tegra: ack the rx dma desc after transfer
terminated") intact: the ack still happens for every terminated
transfer, just before the descriptor is freed instead of after.

Testing was done on Tegra234 (Jetson AGX Orin) only.

Signed-off-by: Austin <austin.schlegel@arthrex.com>
---
Austin (2):
      serial: tegra: fix RX DMA descriptor use-after-free
      serial: tegra: fix TX DMA descriptor use-after-free

 drivers/tty/serial/serial-tegra.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
---
base-commit: 5dad87615c9861cfa366ca984b52f581e861df20
change-id: 20261001-tty-linus-ae90fc64265d

Best regards,
-- 
Austin <austin.schlegel@arthrex.com>

