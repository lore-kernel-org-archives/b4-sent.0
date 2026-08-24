From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 24 Aug 2026 14:58:01 -0700
Subject: [PATCH net v7 4/4] net: ethernet: oa_tc6: Fix for the wrong data
 type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-fix-race-condition-and-crash-v7-4-4323279b18f2@onsemi.com>
References: <20260824-fix-race-condition-and-crash-v7-0-4323279b18f2@onsemi.com>
In-Reply-To: <20260824-fix-race-condition-and-crash-v7-0-4323279b18f2@onsemi.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Parthiban Veerasooran <Parthiban.Veerasooran@microchip.com>, 
 Andrew Lunn <andrew@lunn.ch>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787608678; l=1054;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=no23al67vcDK5tp325bYlmc8jUdp9BwqmZKml1V/MkA=;
 b=SS1uGmOYLtqeBYw5mUfV3ry/SYc9reh8Ps0puXtGB9o27hhcq0IQkRPFPy38oW0n7anLhoDh5
 jM4UKPqy1rRALidlzb2nB08WW7kn5Uue3ZmtZ1qYufHrzPCAn0x82wh
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inadvertently bool data type is used where int is supposed to
be used. This might turn a negative error code into true or
false and sign of the return code would be lost.

Fixes: 8f9bf857e43b ("net: ethernet: oa_tc6: implement internal PHY initialization")
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - New patch. Fixed the wrong data type used.
---
 drivers/net/ethernet/oa_tc6.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index eea00b41fb8d..6fcc5f561d56 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -455,7 +455,7 @@ static int oa_tc6_mdiobus_read(struct mii_bus *bus, int addr, int regnum)
 {
 	struct oa_tc6 *tc6 = bus->priv;
 	u32 regval;
-	bool ret;
+	int ret;
 
 	ret = oa_tc6_read_register(tc6, OA_TC6_PHY_STD_REG_ADDR_BASE |
 				   (regnum & OA_TC6_PHY_STD_REG_ADDR_MASK),

-- 
2.43.0

