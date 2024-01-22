From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 22 Jan 2024 22:33:24 +0800
Subject: [PATCH v3 5/5] net: hifemac: make some functions static
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240122-net-v3-5-f1e80564725b@outlook.com>
References: <20240122-net-v3-0-f1e80564725b@outlook.com>
In-Reply-To: <20240122-net-v3-0-f1e80564725b@outlook.com>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705934004; l=916;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=yN6bxCppLVd3zELKEWeh7jD0R+jNdNUufUTF79X0J6o=;
 b=fvrti5MvFqjgw2F8LuRaZGrYE01OV3iHKLe4ZMKxIonKJM7W9MNqPvDt+hsEMm5jiPZCI3mM6
 gmY6t01+RU6BUBBuIk8dhql6ryOKmlrAh64zb+imlfmWma3ipv/jXHI
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

They are not required to be global, make them static.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/hifemac.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/hifemac.c b/drivers/net/hifemac.c
index d24023eefd..90cc247b3b 100644
--- a/drivers/net/hifemac.c
+++ b/drivers/net/hifemac.c
@@ -418,7 +418,7 @@ static void hisi_femac_get_stats(struct udevice *dev, u64 *data)
 	}
 }
 
-int hisi_femac_of_to_plat(struct udevice *dev)
+static int hisi_femac_of_to_plat(struct udevice *dev)
 {
 	int ret, i;
 	struct hisi_femac_priv *priv = dev_get_priv(dev);
@@ -553,7 +553,7 @@ static int hisi_femac_phy_reset(struct hisi_femac_priv *priv)
 	return 0;
 }
 
-int hisi_femac_probe(struct udevice *dev)
+static int hisi_femac_probe(struct udevice *dev)
 {
 	struct hisi_femac_priv *priv = dev_get_priv(dev);
 	int ret, i;

-- 
2.43.0

