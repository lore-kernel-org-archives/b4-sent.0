From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Tue, 10 Nov 2026 03:37:24 -0600
Subject: [PATCH v3] staging: octeon: remove unnecessary parentheses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261110-octeon-parentheses-cleanup-v1-v3-1-ea6d4ecf2ec5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQqDMBBFryKz7pSM0SJd9R7iIqajDmgiSSot4
 t2beoLC37y/eG+HyEE4wr3YIfAmUbzLoC8F2Mm4kVGemaFU5Y1INehtYu9wNYFdmjhyRDuzca8
 VN0JLg9a6NhURQ3asgQd5n/62yzxJTD58ztxGv/dfcx5hbXvFWnOlmv4xLkbmq/ULdMdxfAGlb
 hUWygAAAA==
X-Change-ID: 20261108-octeon-parentheses-cleanup-v1-c1f3335a411e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794303451; l=2525;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=HpVvmqNpd6mNraRfdV9oEnBYW18VRLrqlhVstvdAHTU=;
 b=TQ5u1kxGwAjDY2wRn/wXd14s2gGSPQSFf2DU5pzJ1HqRG7WLvhstwC2z92TswZLzfKj3UDyTw
 zj9INZOfSFsAULsAFP6WgwuXGSJPABHepQgesXywvIqU8wCnGKqN0lP
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix checkpatch.pl warnings by removing redundant parentheses around
conditional checks.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
Hi Greg,

This patch fixes checkpatch.pl warnings in ethernet.c by removing
unnecessary parentheses.

The v2 text was AI-generated because I don't speak English well
and I tryng to learn b4 workflow.
I try being concise in this v3. Sorry for the noise.
---
Changes in v3:
- Rewrote the cover letter and commit message manually.
- Removed the AI-generated text.
---
 drivers/staging/octeon/ethernet.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index 42ec4b8324a8..f374fdf8f7a9 100644
--- a/drivers/staging/octeon/ethernet.c
+++ b/drivers/staging/octeon/ethernet.c
@@ -262,9 +262,9 @@ static int cvm_oct_common_change_mtu(struct net_device *dev, int new_mtu)
 
 	dev->mtu = new_mtu;
 
-	if ((interface < 2) &&
-	    (cvmx_helper_interface_get_mode(interface) !=
-		CVMX_HELPER_INTERFACE_MODE_SPI)) {
+	if (interface < 2 &&
+	    cvmx_helper_interface_get_mode(interface) !=
+		CVMX_HELPER_INTERFACE_MODE_SPI) {
 		int index = INDEX(priv->port);
 		/* Add ethernet header and FCS, and VLAN if configured. */
 		int max_packet = new_mtu + mtu_overhead;
@@ -308,9 +308,9 @@ static void cvm_oct_common_set_multicast_list(struct net_device *dev)
 	struct octeon_ethernet *priv = netdev_priv(dev);
 	int interface = INTERFACE(priv->port);
 
-	if ((interface < 2) &&
-	    (cvmx_helper_interface_get_mode(interface) !=
-		CVMX_HELPER_INTERFACE_MODE_SPI)) {
+	if (interface < 2 &&
+	    cvmx_helper_interface_get_mode(interface) !=
+		CVMX_HELPER_INTERFACE_MODE_SPI) {
 		union cvmx_gmxx_rxx_adr_ctl control;
 		int index = INDEX(priv->port);
 
@@ -360,9 +360,9 @@ static int cvm_oct_set_mac_filter(struct net_device *dev)
 	union cvmx_gmxx_prtx_cfg gmx_cfg;
 	int interface = INTERFACE(priv->port);
 
-	if ((interface < 2) &&
-	    (cvmx_helper_interface_get_mode(interface) !=
-		CVMX_HELPER_INTERFACE_MODE_SPI)) {
+	if (interface < 2 &&
+	    cvmx_helper_interface_get_mode(interface) !=
+		CVMX_HELPER_INTERFACE_MODE_SPI) {
 		int i;
 		const u8 *ptr = dev->dev_addr;
 		u64 mac = 0;

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261108-octeon-parentheses-cleanup-v1-c1f3335a411e

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

