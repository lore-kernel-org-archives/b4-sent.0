From: =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
Date: Sat, 07 Nov 2026 20:07:56 -0600
Subject: [PATCH 2/4] staging: octeon: fix OF node leak and kernel-doc in
 ethernet-mdio.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-octeon-phy-series-v2-v1-2-d7ab0b4b3f17@gmail.com>
References: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
In-Reply-To: <20261107-octeon-phy-series-v2-v1-0-d7ab0b4b3f17@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Oscar_Alejandro_S=C3=A1nchez_Lucero?= <aleszlucero@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794103676; l=1233;
 i=aleszlucero@gmail.com; s=20261104; h=from:subject:message-id;
 bh=6FhHXWZH7mRV6V1TF5pn2Y16qtYn8oRyRinRCkzOsIA=;
 b=1B2lkTS2xomrFU5EcWrgd6ybRCBw78hnPrGIxP/g8Nab9vW7cG/8LdjfQUMWqd2qCGI28qtJ8
 kG657CHA6uADzkflVhbWCpjhPfzCkyDm0v5EcY98kh/Lz9g3MxeKO1T
X-Developer-Key: i=aleszlucero@gmail.com; a=ed25519;
 pk=zRzEBMID7l1FXqr2CjfnlIn++3m3N05FuNYb5zPA3cw=
X-Endpoint-Received: by B4 Relay for aleszlucero@gmail.com/20261104 with auth_id=1410
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a reference count leak in cvm_oct_phy_setup_device() where the
device_node pointer 'phy_node' was not released if of_phy_connect()
returned NULL on a probe deferral scenario. Balance the reference count
by calling of_node_put() within the error path block.

Additionally, correct the documentation style of the function by
replacing 'Returns' with the standard 'Return:' keyword to comply with
kernel-doc scripting requirements.

Signed-off-by: Oscar Alejandro Sánchez Lucero <aleszlucero@gmail.com>
---
 drivers/staging/octeon/ethernet-mdio.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/staging/octeon/ethernet-mdio.c b/drivers/staging/octeon/ethernet-mdio.c
index 211423059e30..05bc536ebded 100644
--- a/drivers/staging/octeon/ethernet-mdio.c
+++ b/drivers/staging/octeon/ethernet-mdio.c
@@ -151,11 +151,13 @@ int cvm_oct_phy_setup_device(struct net_device *dev)
 
 	phydev = of_phy_connect(dev, phy_node, cvm_oct_adjust_link, 0,
 				priv->phy_mode);
-	of_node_put(phy_node);
 
-	if (!phydev)
+	if (!phydev) {
+		of_node_put(phy_node);
 		return -EPROBE_DEFER;
+	}
 
+	of_node_put(phy_node);
 	priv->last_link = 0;
 	phy_start(phydev);
 

-- 
2.56.0

