From: Haseeb Malik <haseebulhaq55@gmail.com>
To: Sabrina Dubroca <sd@queasysnail.net>, netdev@vger.kernel.org
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 linux-kernel@vger.kernel.org
Subject: [PATCH net-next] macsec: check for duplicate SCIs before
 registering the device
Date: Sun, 11 Oct 2026 21:57:11 +0000
Message-ID: <20261011-macsec-early-sci-check-2b1f06af193f@gmail.com>
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
MIME-Version: 1.0
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791756119; l=2042;
 i=haseebulhaq55@gmail.com; s=default; h=from:subject:message-id;
 bh=3yrY3KSdmX2Lbj0TP8rJOIrBxb8TNoGAzNCgkYC5p74=;
 b=L5t3/FxbcRCZzHeu1Bp9cVnk4u93qX8LBwHeRupzFdJL6irVlyKzONIkG1rDbzH+NS7LSCIfl
 wByRJDDreD2A+fJATZUFNk1vaZng9LpqZUgYgZUPGwOwqDl7RLhyyWo
X-Developer-Key: i=haseebulhaq55@gmail.com; a=ed25519;
 pk=U/yCVc6cTsqDqxWLzvoONZ7DUA3EfRU+rfO9Xxo4p2w=
X-Endpoint-Received: by B4 Relay for haseebulhaq55@gmail.com/default with auth_id=1026
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

macsec_newlink() registers and links the device before rejecting a
duplicate SCI. Registration can emit link notifications for a device
whose creation ultimately fails with -EBUSY.

The SCI is already resolved before SecY initialization, so check for a
duplicate there and return -EBUSY directly. Remove the now-unused unlink
label while preserving cleanup for failures after registration.

Suggested-by: Sabrina Dubroca <sd@queasysnail.net>
Link: https://lore.kernel.org/netdev/ar2KmwhtCMbOKLsG@krikkit/
Assisted-by: LLM
Signed-off-by: Haseeb Malik <haseebulhaq55@gmail.com>
---
Tested on arm64 in virtme with KASAN and lockdep: all 15 MACsec selftests
and 80 offload/cleanup cycles pass. Rejected-device link notifications
observed by the diagnostic drop from two to zero.

 drivers/net/macsec.c | 9 +++------
 1 file changed, 3 insertions(+), 6 deletions(-)

diff --git a/drivers/net/macsec.c b/drivers/net/macsec.c
index 409fd855235ba29125e39bfd80e1c5656aea784f..4e3020586b1e53c5a17f7e31c1f15b87f6443e17 100644
--- a/drivers/net/macsec.c
+++ b/drivers/net/macsec.c
@@ -4264,6 +4264,9 @@ static int macsec_newlink(struct net_device *dev,
 	if (sci == MACSEC_UNDEF_SCI)
 		sci = dev_to_sci(dev, MACSEC_PORT_ES);
 
+	if (rx_handler && sci_exists(real_dev, sci))
+		return -EBUSY;
+
 	/* Registration can notify listeners before returning. */
 	macsec_init_secy(dev, sci, icv_len);
 	if (data) {
@@ -4284,11 +4287,6 @@ static int macsec_newlink(struct net_device *dev,
 	if (err < 0)
 		goto unregister;
 
-	if (rx_handler && sci_exists(real_dev, sci)) {
-		err = -EBUSY;
-		goto unlink;
-	}
-
 	/* If h/w offloading is available, propagate to the device */
 	if (macsec_is_offloaded(macsec)) {
 		const struct macsec_ops *ops;
@@ -4320,7 +4318,6 @@ static int macsec_newlink(struct net_device *dev,
 
 del_dev:
 	macsec_del_dev(macsec);
-unlink:
 	netdev_upper_dev_unlink(real_dev, dev);
 unregister:
 	unregister_netdevice(dev);

base-commit: 8df0638138d3e0344fd1fb36cf2d1ca1cf5028f0

