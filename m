From: Fan Ye <fy15309206903@gmail.com>
Date: Tue, 11 Aug 2026 13:20:49 +0000
Subject: [PATCH net v3 1/2] net: thunderbolt: Release the Rx HopID that was
 handed out on mismatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-b4-tbnet-hopid-v3-1-9e75d1b51331@gmail.com>
References: <20260811-b4-tbnet-hopid-v3-0-9e75d1b51331@gmail.com>
In-Reply-To: <20260811-b4-tbnet-hopid-v3-0-9e75d1b51331@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786454448; l=2078;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=lESY9+I3jf4v1krnmOpqlJtStY5pn7YDNxvIAIgBURM=;
 b=l+k7+Gl4blEYewjBjyTKIRvXUm48/QslNgv9EF7v35WCJDO56STd65s/Go5ugXdYV5puJ/en5
 qn0F4sPV6vvDEAMEf/OgijEX/otAR7oGAuI1NaXr5C+9f6OOW/VHQk1
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_xdomain_alloc_in_hopid() passes the wanted HopID to ida_alloc_range()
as the lower bound, so a taken id is not an error there: the allocator
returns the next free one above it. tbnet_connected_work() asks for the
peer's transmit path, treats any other id as a failure and returns
without releasing what it got, so that allocation stays live for the rest
of the XDomain connection with nothing left holding a reference to it.

Release the id when it is not the one we asked for, the same way the
error unwind at the end of the function releases the expected one.

Fixes: 180b0689425c ("thunderbolt: Allow multiple DMA tunnels over a single XDomain connection")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5
Signed-off-by: Fan Ye <fy15309206903@gmail.com>
Acked-by: Mika Westerberg <mika.westerberg@linux.intel.com>
---
Reached without fault injection on an ASMedia ASM4242 host-to-host link
when the peer drops out mid bring-up: 23 times across two hosts in one
run of interface down/up cycling. Each one ended in the XDomain
connection being rebuilt, which recreates the ida and disposes of the
leaked id, so what I am claiming here is the leak, not a symptom.

Patch 2/2 edits the lines this one adds and will not apply without it.

v3:
- Rewrote the commit message; dropped the quoted source and probe output.

v2: https://lore.kernel.org/netdev/20260810-b4-tbnet-hopid-v2-0-0eee557e75df@gmail.com/
---
 drivers/net/thunderbolt/main.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/net/thunderbolt/main.c b/drivers/net/thunderbolt/main.c
index 98893732bc6e..e5199a87ea7a 100644
--- a/drivers/net/thunderbolt/main.c
+++ b/drivers/net/thunderbolt/main.c
@@ -647,6 +647,8 @@ static void tbnet_connected_work(struct work_struct *work)
 	ret = tb_xdomain_alloc_in_hopid(net->xd, net->remote_transmit_path);
 	if (ret != net->remote_transmit_path) {
 		netdev_err(net->dev, "failed to allocate Rx HopID\n");
+		if (ret >= 0)
+			tb_xdomain_release_in_hopid(net->xd, ret);
 		return;
 	}
 

-- 
2.43.0

