From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Wed, 11 Nov 2026 21:48:33 -0600
Subject: [PATCH v4 2/2] staging: octeon: match exact interface names in
 pow_send_list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261111-octeon-init-pipeline-v1-v4-2-5b4f8e613ae1@gmail.com>
References: <20261111-octeon-init-pipeline-v1-v4-0-5b4f8e613ae1@gmail.com>
In-Reply-To: <20261111-octeon-init-pipeline-v1-v4-0-5b4f8e613ae1@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794455321; l=1426;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=8E71kLdZrxiYjTNdPeIwjDJ9PhrdCS1LH+eWfrSvIbA=;
 b=5g1uRcEn9QC+kz9cnr5UIiKq5g/821Pxcu80xa98/BNR7PEqrYT612KWrPM53S8JJcA/8Yr61
 TjpDoPqjNOtAV+DN6YORQkkenMJdcOAZfYcJrlskPMcUXR8eL93uL8I
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cvm_oct_common_init() searches pow_send_list using strstr(), which matches
substrings instead of exact interface names.

Split a local copy of pow_send_list on comas with strsep() and compare
each entry using strcmp().

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet.c | 20 +++++++++++++++++---
 1 file changed, 17 insertions(+), 3 deletions(-)

diff --git a/drivers/staging/octeon/ethernet.c b/drivers/staging/octeon/ethernet.c
index c77678cb351f..653cf3727ba7 100644
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

-- 
2.56.0

