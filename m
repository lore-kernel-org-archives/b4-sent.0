From: Austin Schlegel <schlegelas@outlook.com>
Subject: [PATCH v2 0/2] serial: tegra: fix RX/TX DMA descriptor
 use-after-free
Date: Wed, 14 Oct 2026 23:29:59 -0400
Message-Id: <20261014-serial-tegra-dma-uaf-v2-0-b142b31b67e3@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MSQqAMAwAvyI5G2irVPQr4iHaqAE3WhVB/LvV4
 8DM3BDYCweokhs8nxJkXSKYNIFupGVgFBcZjDJWK53j59OEOw+e0M2EB/WYleysKZSm1kJMN8+
 9XP+2bp7nBbKP2WpmAAAA
X-Change-ID: 20261014-serial-tegra-dma-uaf-39ed62701ab6
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Austin Schlegel <austin.schlegel@arthrex.com>, 
 Austin Schlegel <schlegelas@outlook.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792035000; l=2548;
 i=schlegelas@outlook.com; s=20261001; h=from:subject:message-id;
 bh=IBuh8V/uOu8n3l2k9h8iBPBCSdskQXtHgw9YykzfWQ0=;
 b=tq2kzMb86aNh7fEUjolwDWbAM6s80eKTE+KUQmtkedKBxM5OpkDMBwNKxaSzeGoEHV+gwoAsx
 WI6Gr3QFfqsCOl1TwHjBCM9B+6zbsbFFtdM3NNbGfOkVtslxOFBcaJk
X-Developer-Key: i=schlegelas@outlook.com; a=ed25519;
 pk=ddgmH7VQaSWderjJFy4hDyq+P7hdHupPxQvwnGRBzCs=
X-Endpoint-Received: by B4 Relay for schlegelas@outlook.com/20261001 with auth_id=1098
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
kfence.sample_interval=1 with zero further reports. It keeps the
descriptor-leak fix from commit b31245b94207 ("serial: tegra: ack
the rx dma desc after transfer terminated") intact: the ack still
happens for every terminated RX transfer, just before the descriptor
is freed instead of after.

Patch 2/2 (TX) is the same ordering bug in the analogous TX path
(tegra_uart_stop_tx()), present since the driver was added, and found
by code inspection once the RX bug was understood. It has not been
reproduced on hardware - triggering it requires stopping an in-flight
TX DMA transfer at the right moment, which did not occur during RX
testing - but it is the identical dmaengine_terminate_all()-then-ack
pattern in the same driver against the same DMA engine, so I'm sending
it alongside the RX fix rather than leaving it unfixed.

Testing was done on Tegra234 (Jetson AGX Orin) only.

Signed-off-by: Austin Schlegel <schlegelas@outlook.com>
---
Changes in v2:
- Commit message updates only; no code changes.
- Patch 1: removed an inaccurate statement that the freed descriptor
  is accessed in tegra_uart_rx_dma_complete(); updated the soak test
  duration to 24+ hours.
- Patch 2: removed an inaccurate flush example; added Fixes: tag.
- Switched to my personal email address (v1 was sent from
  austin.schlegel@arthrex.com).
- Link to v1: https://lore.kernel.org/r/20261001-tty-linus-v1-0-ecb8576c802d@arthrex.com

---
Austin Schlegel (2):
      serial: tegra: fix RX DMA descriptor use-after-free
      serial: tegra: fix TX DMA descriptor use-after-free

 drivers/tty/serial/serial-tegra.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261014-serial-tegra-dma-uaf-39ed62701ab6

Best regards,
-- 
Austin Schlegel <schlegelas@outlook.com>

