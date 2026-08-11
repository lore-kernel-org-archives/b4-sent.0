From: Fan Ye <fy15309206903@gmail.com>
Subject: [PATCH net v3 0/2] net: thunderbolt: two fixes for the failed
 bring-up path
Date: Tue, 11 Aug 2026 13:20:48 +0000
Message-Id: <20260811-b4-tbnet-hopid-v3-0-9e75d1b51331@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALAhe2oC/yWMSQ6DMBAEv4L6nJHwwiK+EuUQ4wEmB4NsByEh/
 h4nOVarq04kjsIJQ3Ui8i5J1lDA3CqMyzPMTOILQ9e6rXulyFnKLnCmZd3Ek2+s7qxypjUeRdo
 iT3L8gneUGx7/Mb3di8f8TeG6PrSTBmZ3AAAA
X-Change-ID: 20260811-b4-tbnet-hopid-d542741b363d
To: Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786454448; l=1416;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=1cUEhKpwhbhOlu1jJZ6mAX5yeVy7AZ4oG+h0MJFNlQA=;
 b=/a2kRJtmMh7Lp1jXHqXUcVtWdTmUYeqNFUSfzjP9GrQ6Y6hCcvM8EfV2eZfrLFTvgki9a1ZPo
 eyg4x9DzkY6AFUxktvGt54Zg0SkM69UgwlMjtzCYWWd0C4ZCwVIhHJ9
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two separate defects reached through the same branch in
tbnet_connected_work(), found on an ASMedia ASM4242 host-to-host link
when the peer drops out while a connection is being brought up.

  1 releases the HopID the allocator handed out when it is not the one
    that was asked for.  Today it stays allocated for the rest of the
    XDomain connection.

  2 marks the connection down on the failure paths, so the next
    tbnet_tear_down() does not run a second teardown over work that was
    already undone: stopping rings that are already stopped, which is
    fatal under panic_on_warn, and handing back a HopID this connection
    never owned.

Patch 2 edits the lines patch 1 adds, so it has to come second.

Changes in v3:
- Cut both commit messages down after review; the code is unchanged
  apart from the comment on the new helper in patch 2, now one line.
- Link to v2: https://lore.kernel.org/netdev/20260810-b4-tbnet-hopid-v2-0-0eee557e75df@gmail.com/

---
Fan Ye (2):
      net: thunderbolt: Release the Rx HopID that was handed out on mismatch
      net: thunderbolt: Mark the connection down when bringing it up fails

 drivers/net/thunderbolt/main.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)
---
base-commit: d58772d8520c7ef247c4b95c9bd76d3a25da9ff5
change-id: 20260811-b4-tbnet-hopid-d542741b363d

Best regards,
--  
Fan Ye <fy15309206903@gmail.com>

