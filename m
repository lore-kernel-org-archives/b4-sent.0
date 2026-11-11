From: Martin Belanger <martin.nvme.dev@gmail.com>
Subject: [PATCH v2 0/3] nvme-tcp: consume TLS records without application
 data on a live queue
Date: Wed, 11 Nov 2026 15:42:38 -0500
Message-Id: <20261111-nvme-tcp-live-ctrlrec-v2-0-6295202b84de@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNyw6CMBBFf4XM2jEtj5K68j8Mi1JHGMMrbW00p
 P8u4Ae4PMm5567gyTF5uGQrOIrseZ42yE8Z2N5MHSHfN4Zc5EpKoXGKI2GwCw4cCW1wgyOLZVX
 oVhdaFELCtl0cPfh9dG/Nj/2rfZINe2w3evZhdp/jOMrd+/cRJQos69YoqWpBqrp2o+HhbOcRm
 pTSFzrVZGnMAAAA
X-Change-ID: 20261109-nvme-tcp-live-ctrlrec-4539b9390301
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: Martin Belanger <martin.nvme.dev@gmail.com>, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794429760; l=3589;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=hXXbItxrwv78xxvvG5U42pKUfzgkaD4CVGRVQghqOfE=;
 b=uUgeHVoq6upcSqsLQTRCBiHyy6V7OpTLIhbE1iuAKvsd7x//4JeG41nwTbFP9gxBJe7lRmNAn
 eESbXznFiNtAW+EUYZn+tHxzIyyl4PfOIzvZRTu6uei7Al5uEn3+4QL
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After the TLS handshake, a peer may send records that carry no
application data: a NewSessionTicket, a KeyUpdate or an alert.
tls_sw_read_sock() cannot pass such a record to nvme_tcp_recv_skb().
It returns -EINVAL and leaves the record at the head of the receive
queue. Since commit 288cfa187208 ("nvme-tcp: start error recovery when
read_sock fails"), nvme-tcp then starts error recovery, and the
controller reconnects.

TLS 1.3 allows a server to send a NewSessionTicket at any time after
the handshake (RFC 8446, section 4.6.1). Alerts can also arrive at any
time.

Patch 1 aligns the control message buffer that receives the record
type.

Patch 2 moves the TLS record read loop into a helper. No functional
change.

Patch 3 reads the record with recvmsg() when read_sock() returns
-EINVAL, and handles it by type. Handshake messages other than
KeyUpdate are discarded and alerts are logged. A fatal alert, a
KeyUpdate or another record type fails the queue.

Patch 3 detects a KeyUpdate only when it is the first handshake
message of the record. A KeyUpdate that follows another message in the
same record is discarded with it. The next record then fails to
decrypt, and the queue fails as it does today.

All patches are tagged for stable, because 288cfa187208 is in 6.12.117,
6.18.63 and 7.3.4.

Tool use
========

I developed this series with the help of an LLM coding assistant. It
drafted code, tests and changelogs, and helped with analysis of the
kTLS and sunrpc sources. I reviewed, edited and tested all of it, and
I am responsible for the content.

Testing
=======

Host and target in one VM (virtme-ng), on 7.4-rc2. A test-only change
to net/tls makes the target send records on a live I/O queue during
I/O. Each case writes data and reads it back with O_DIRECT.

  Records sent by the target   7.4-rc2     With this series
  ---------------------------  ----------  --------------------------
  NewSessionTicket, 64 bytes   reconnect   queue stays live
  2 x 300, 2 x 1000, 6 x 64    reconnect   queue stays live
  close_notify alert           reconnect   queue stays live
  warning alert (90)           reconnect   queue stays live, logged
  fatal alert (40)             reconnect   reconnect, logged
  KeyUpdate                    reconnect   reconnect, logged

Data was correct in all cases. Also built with W=1, with and without
CONFIG_NVME_TCP_TLS.

Poll queues are not tested. Polled I/O hangs in my test VM, also on
7.4-rc2 without this series.

Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
Changes in v2:
- New patch 1: use a union with struct cmsghdr for the record type
  buffer, as sunrpc does. (Sashiko)
- Patch 3: on a poll queue, nvme_tcp_poll() and nvme_tcp_io_work()
  could both read the same record. A queue flag lets only one of them
  read it. (Sashiko)
- Patch 3: drop a log line that repeated the error of
  nvme_tcp_try_recv().
- Link to v1: https://patch.msgid.link/20261109-nvme-tcp-live-ctrlrec-v1-0-47ba61670e65@gmail.com

---
Martin Belanger (3):
      nvme-tcp: use an aligned buffer for the TLS record type
      nvme-tcp: move the TLS record read loop into a helper
      nvme-tcp: consume TLS records without application data

 drivers/nvme/host/tcp.c | 175 +++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 144 insertions(+), 31 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261109-nvme-tcp-live-ctrlrec-4539b9390301

Best regards,
--  
Martin Belanger <martin.nvme.dev@gmail.com>

