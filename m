From: Martin Belanger <martin.nvme.dev@gmail.com>
Subject: [PATCH 0/2] nvme-tcp: handle TLS control records at connect and on
 receive errors
Date: Mon, 26 Oct 2026 14:09:43 -0400
Message-Id: <20261026-nvme-tcp-ctrlrec-fixes-v1-0-ebf6ff7eff34@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCUAwEf6XkbKCvWgV/RTy06VYj+izJswil/
 27Uwx6GZWYhhymcjtVChlldnzkgbSqSa5cvYB2CqambfYpxnh/gIhNLsbtBeNQ3nNsxydDu6sO
 27yjkyfA7wj2d/+yv/gYp3xqt6wdHTW6legAAAA==
X-Change-ID: 20261026-nvme-tcp-ctrlrec-fixes-5f1cd54073ba
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793038187; l=2128;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=3hTAzrQJfgElLUy2dxnWBPcmYnvUEDdOPYD2sRIU/0g=;
 b=iQQCHjO1s/DBlbEGXiWuHp59XYALtBKQvAVw7ggCh/0qNPDM8zpPbc/a/fTIYvqg3xIIRnPzb
 jCRWH4eV55OBPFaLPIlAQmq/P2cdng7mpRhoPu/NfTXIqDh3NZB81oM
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A TLS 1.3 peer can send records that carry no application data, for
example a NewSessionTicket right after the handshake. nvme-tcp does not
handle them correctly. This series fixes two cases.

Patch 1: when read_sock() returns an error, nvme-tcp does not start
error recovery. The queue stops receiving until a command times out.
With a NewSessionTicket on a live queue, I/O stalls until the I/O
timeout (30 seconds by default). With this patch, recovery starts at
once. This also applies to plain TCP.

Patch 2: a NewSessionTicket that arrives before the ICResp fails the
connection with "failed to receive icresp, error -104". A target that
sends a ticket at once, such as an OpenSSL-based target, cannot be
reached. With this patch, the ticket is discarded and the connection
succeeds. An alert in place of the ICResp is now reported with its code,
instead of as error -104.

These patches replace patch 1/2 of Hannes's "nvme,tls: minimal handling
for TLS records":
https://lore.kernel.org/all/20260922133708.84522-1-hare@kernel.org/

Patch 2/2 of that series (the net/tls errno change) will be posted to
netdev separately after 7.4-rc1. It will not change
tls_sw_splice_read(), because that errno is visible to user space.
After that, a follow-up nvme-tcp patch will read control records on a
live queue, so a NewSessionTicket no longer causes a reconnect.

Tested with host and target in one VM, with a test-only change to
net/tls that makes the target send a NewSessionTicket or an alert.
Also tested on plain TCP, and built with CONFIG_NVME_TCP_TLS=n.

Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
Martin Belanger (2):
      nvme-tcp: start error recovery when read_sock fails
      nvme-tcp: skip TLS control records while waiting for the ICResp

 drivers/nvme/host/tcp.c | 173 +++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 150 insertions(+), 23 deletions(-)
---
base-commit: 6b4b543fa18757297ac756a6fe6e64f506b7844a
change-id: 20261026-nvme-tcp-ctrlrec-fixes-5f1cd54073ba

Best regards,
--  
Martin Belanger <martin.nvme.dev@gmail.com>

