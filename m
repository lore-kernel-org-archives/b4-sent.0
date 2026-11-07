From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 01:36:54 -0600
Subject: [PATCH] staging: octeon: match exact interface names in
 pow_send_list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-pow-send-list-v1-1-2d28dac15e88@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQqAMAxA0auUzAYakYpeRRxKjRqQVhpRQby7x
 fEN/z+gnIUVevNA5lNUUiygykBYfVwYZSqG2taOyLaYwsEp4p4uVI4TbqIHdl3TsnOe7GyhpHv
 mWe5/O4zv+wFlhsHGZgAAAA==
X-Change-ID: 20261107-octeon-pow-send-list-9947e66a10f0
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794037015; l=1785;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=LZq7fls08J5yskhU+V6oLqK+G4OJgckR9NNE461HpQk=;
 b=R565vkHb4kNeLNhL4BNL6i0osW23mL9ij/xRVWJrd12UEoNI1JiVQB/l3CSD4StUXHrJ+H60z
 wwfgmMKoINgBPEsCJ1zP/TCVRF8zMwLkP3FPAXImfu5FwvEeV791yAh
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_common_init() checks whether dev->name is present in the
comma-separated pow_send_list module parameter using strstr(). This
causes false positives when one interface name is a prefix of another
(for example, matching "eth1" when pow_send_list contains "eth10").

Copy pow_send_list to a temporary buffer, tokenize it with strsep(),
and compare each comma-separated entry with strcmp().

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet.c | 20 +++++++++++++++++---
 1 file changed, 17 insertions(+), 3 deletions(-)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index 42ec4b8324a8..6684eeb3fc8f 100644
--- a/drivers/staging/octeon/ethernet.c
+++ b/drivers/staging/octeon/ethernet.c
@@ -431,9 +431,23 @@ int cvm_oct_common_init(struct net_device *dev)
 	 * Force the interface to use the POW send if always_use_pow
 	 * was specified or it is in the pow send list.
 	 */
-	if ((pow_send_group != -1) &&
-	    (always_use_pow || strstr(pow_send_list, dev->name)))
-		priv->queue = -1;
+	if (pow_send_group != -1) {
+		if (always_use_pow) {
+			priv->queue = -1;
+		} else if (pow_send_list[0]) {
+			char list[sizeof(pow_send_list)];
+			char *p = list;
+			char *token;
+
+			strscpy(list, pow_send_list, sizeof(list));
+			while ((token = strsep(&p, ",")) != NULL) {
+				if (!strcmp(token, dev->name)) {
+					priv->queue = -1;
+					break;
+				}
+			}
+		}
+	}
 
 	if (priv->queue != -1)
 		dev->features |= NETIF_F_SG | NETIF_F_IP_CSUM;

---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-octeon-pow-send-list-9947e66a10f0

Best regards,
-- 
Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>

