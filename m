From: Martin Belanger <martin.nvme.dev@gmail.com>
Subject: [PATCH 0/2] nvme-tcp: consume TLS records without application data
 on a live queue
Date: Mon, 09 Nov 2026 14:04:52 -0500
Message-Id: <20261109-nvme-tcp-live-ctrlrec-v1-0-47ba61670e65@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTuQNCrEq4iLdvzVkRrLJAah9
 O5GXX6L9xbKMEWmQ7eQoWrWZ2rwm47kNqQrWM/N1Lt+772LnOoDXGTmSStYik0G4e0uxDGG6IL
 z1NrZcNH373s8/Z1f4x1SvjNa1w8p+XbweQAAAA==
X-Change-ID: 20261109-nvme-tcp-live-ctrlrec-4539b9390301
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Hannes Reinecke <hare@kernel.org>
Cc: Martin Belanger <martin.nvme.dev@gmail.com>, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Martin Belanger <martin.belanger@dell.com>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251097; l=2856;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=+RFQb7lReLCFe1adR320Vhaj1EAjoE628nMe1pJcegU=;
 b=KE7Dj2rsVobi2ZeWZ0BYkyr1AKi+lTSCDHAksQUcSkmM9Ui3OB1kf4+GUlaiORDKlQWhcd/1X
 EY3H4rS5EeFC3sNueTdsMS7uXdLOQNmkRvMcTTz3E+0Il3+uC+stlZl
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

Patch 1 moves the TLS record read loop into a helper. No functional
change.

Patch 2 reads the record with recvmsg() when read_sock() returns
-EINVAL, and handles it by type. Handshake messages other than
KeyUpdate are discarded and alerts are logged. A fatal alert, a
KeyUpdate or another record type fails the queue.

This is the follow-up announced in the cover letter of "nvme-tcp:
handle TLS control records at connect and on receive errors":
https://patch.msgid.link/20261027-nvme-tcp-ctrlrec-fixes-v2-0-9656395ebcf2@gmail.com

Both patches are tagged for stable, because 288cfa187208 is being
backported to 6.12, 6.18 and 7.3.

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

Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
Martin Belanger (2):
      nvme-tcp: move the TLS record read loop into a helper
      nvme-tcp: consume TLS records without application data

 drivers/nvme/host/tcp.c | 146 ++++++++++++++++++++++++++++++++++++++++--------
 1 file changed, 124 insertions(+), 22 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261109-nvme-tcp-live-ctrlrec-4539b9390301

Best regards,
--  
Martin Belanger <martin.nvme.dev@gmail.com>

