From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Subject: [PATCH 0/2] Fix to possible skb leak due to race condtion in tx
 path
Date: Sun, 21 Jun 2026 21:32:56 -0700
Message-Id: <20260621-fix-race-condition-and-crash-v1-0-87e290d9357f@onsemi.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPi6OGoC/x3MMQrDMAxA0asEzRXYJjYkVykdhKwmWuwgl1IIu
 XtExw+Pf8IQUxmwTieYfHVobx7xMQHv1DZBrd6QQiqhpIhv/aERC3JvVT/OkVpFNho7LnMNOVM
 pmWfwxWHi/r9/vq7rBtBsbxRuAAAA
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Andrew Lunn <andrew@lunn.ch>, 
 Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782102789; l=2224;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=SlilqLnNR3Q4g+urDMRHsH9UzQw3hURV/MRbu5xRLR8=;
 b=q8rYtD4fr9w/nMSFulKO+HEpL6q6YTqMovs76yAYIPhrwzjWahoc4RH7IsycUYGjiK79q/2iU
 GkIp0lV6PY+A0HDI902sQX2KM3349U69IumWjyUhCp9GE1YF/POyrMT
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now the traffic is handled in threaded IRQ, and the
disable_traffic flag is checked before handling the
data, new race condition is exposed, in which
buffer may leak, if threaded IRQ interrupts the
trasmit path midway.

With this change, disable_traffic and waiting_tx_skb
pointer are protected by spin lock/unlock pair.

This is highlighted in Sashiko review
https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20260611-level-trigger-v5-0-4533a9e85ce2%40onsemi.com

Also on buffer overrun condition, probably due to loss of
SPI data chunks, receive path doesn't see the expected
data chunk with end_valid bit set. As a result, driver
keeps adding data chunks to the skb before running out
of space and kernel panic is seen.

With this change, before adding data to the skb, if there
is no space, skb is freed and driver starts looking for
new frame by looking for a data chunk with start_valid
bit set.

[  705.405490] skbuff: skb_over_panic: text:ffffffd2eb72a264 len:1600 put:64 head:ffffff804e5cdc40 data:ffffff804e5cdc80 tail:0x680 end:0x640 dev:eth1
[  705.405569] ------------[ cut here ]------------
[  705.405575] kernel BUG at net/core/skbuff.c:214!
[  705.405589] Internal error: Oops - BUG: 00000000f2000800 [#1]  SMP

[ 6703.427690] Call trace:
[  705.925157]  skb_panic+0x58/0x68 (P)
[  705.928726]  skb_put+0x74/0x80
[  705.931772]  oa_tc6_update_rx_skb+0x44/0x98 [oa_tc6_mod]
[  705.937084]  oa_tc6_macphy_threaded_irq+0x3f4/0x900 [oa_tc6_mod]
[  705.943084]  irq_thread_fn+0x34/0xb8
[  705.946654]  irq_thread+0x1a0/0x300
[  705.950134]  kthread+0x138/0x150
[  705.953356]  ret_from_fork+0x10/0x20

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
Selvamani Rajagopal (2):
      Protect skb pointer used by two different kernel instances
      net: ethernet: oa_tc6: Improvement in buffer overflow handling

 drivers/net/ethernet/oa_tc6.c | 75 +++++++++++++++++++++++++++----------------
 1 file changed, 48 insertions(+), 27 deletions(-)
---
base-commit: d07d80b6a129a44538cda1549b7acf95154fb197
change-id: 20260621-fix-race-condition-and-crash-94d055a665c4

Best regards,
-- 
Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

