From: Martin Belanger <martin.nvme.dev@gmail.com>
Subject: [PATCH v2 0/2] nvme-tcp: handle TLS control records at connect and
 on receive errors
Date: Tue, 27 Oct 2026 06:38:51 -0400
Message-Id: <20261027-nvme-tcp-ctrlrec-fixes-v2-0-9656395ebcf2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNSw6CMBCGr0K6dgwtr8SV9zAsYJiBMbzS1kZDu
 LsFD+DiX3z5X5tyZIWcuiWbshTEyTJHMJdE4dDMPYF0kZVJTamjYA4TgccV0NvREgLLmxwUrLE
 r8rTK2kbF8mrpNGL3Uf/YvdonoT/WjsQgzi/2cz4HfeT+ngQNKVDLJXNFzFl+76dGxisuk6r3f
 f8CZOUpQM4AAAA=
X-Change-ID: 20261026-nvme-tcp-ctrlrec-fixes-5f1cd54073ba
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793097538; l=2782;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=xDMOiq++9UZ29kjwcpP4dDWjnCBrv+AXCwcTDZukADk=;
 b=yVaGlqySFRyykT+BVlZcGQur1fUfb2FlJzxyevbNmIqv2leBqsWvvKOFEKklG5m4NT4m4gnsG
 F8gkMJYnhCdDotd9ethcPAuOo3q5UoaeoEIgXtJ+kCe/Al8LHjENB5e
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
net/tls that makes the target send NewSessionTickets of 64 to 1000
bytes, or an alert.
Also tested on plain TCP, and built with CONFIG_NVME_TCP_TLS=n.

Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
Changes in v2:
- Patch 2: pass a control buffer when draining a record. Without it,
  kTLS fails a ticket longer than 128 bytes with -EIO. (Sashiko)
- Patch 2: report a peer that closes before the ICResp as -ECONNRESET.
  (Sashiko)
- Patch 1: start error recovery under the socket lock, before
  release_sock() processes the backlog. (Sashiko)
- Patch 2: cite RFC 9846 section 4.7.1 in the commit message. (Hannes)
- Kept Hannes's Reviewed-by on both patches. The changes since v1 are
  small fixes found in review.
- Link to v1: https://patch.msgid.link/20261026-nvme-tcp-ctrlrec-fixes-v1-0-ebf6ff7eff34@gmail.com

---
Martin Belanger (2):
      nvme-tcp: start error recovery when read_sock fails
      nvme-tcp: skip TLS control records while waiting for the ICResp

 drivers/nvme/host/tcp.c | 175 ++++++++++++++++++++++++++++++++++++++++++------
 1 file changed, 153 insertions(+), 22 deletions(-)
---
base-commit: 6b4b543fa18757297ac756a6fe6e64f506b7844a
change-id: 20261026-nvme-tcp-ctrlrec-fixes-5f1cd54073ba

Best regards,
--  
Martin Belanger <martin.nvme.dev@gmail.com>

