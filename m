From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 05 Aug 2026 12:52:10 +0800
Subject: [PATCH net] macsec: check offload ops before inserting TX tag
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-macsec-fixes-v1-1-634d7679a030@outlook.com>
X-B4-Tracking: v=1; b=H4sIAHrBcmoC/x3LQQqAIBBA0avIrBMmwZKuEi3MxppFFk5EIN09a
 fn4/AJCmUlgUAUy3Sx8pIq2URA2n1bSvFSDQdOhQ6t3H4SCjvyQ6MU4nH3s0VoDdTkz/aEeIyS
 6YHrfDzru88FjAAAA
X-Change-ID: 20260805-macsec-fixes-d280baf70552
To: Sabrina Dubroca <sd@queasysnail.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 "Radu Pirea (NXP OSS)" <radu-nicolae.pirea@oss.nxp.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1852;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=dnNbOmnffeebhe2aAVXh9WY4hPJFAjjHfVNB3XhEz6E=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrKKDhz9P9Nb8uSoy8fejEx82N5/VnuG76tj+9vcmP
 2ue5tQIPHPrKGVhEONikBVTZDlecOmbhe8W3S0+W5Jh5rAygQxh4OIUgIk8E2ZkuHC/sCd2a9mB
 A1f8JkjPuH7xAqNb2ExXlqK+/KTLtZcLPRn+52+4v8jswKfbecrl+5tkHvgeFGVbYlPu5lp7R/I
 j9yxRVgBiRVBS
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

macsec_insert_tx_tag() takes the ops pointer returned by
macsec_get_ops() and dereferences it straight away:

	ops = macsec_get_ops(macsec, &ctx);
	skb_final_len = skb->len - ETH_HLEN + ops->needed_headroom +
		ops->needed_tailroom;

macsec_get_ops() returns NULL whenever the offload is no longer live:
for MACSEC_OFFLOAD_PHY, macsec_check_offload() requires
real_dev->phydev to still be attached.

phy_detach() clears real_dev->phydev, e.g. when the lower device is
brought down and its driver calls phy_disconnect() from ndo_stop(),
when the PHY driver is unbound, or when an SFP module is removed under
phylink. A frame sent after that point reaches macsec_insert_tx_tag()
with ops == NULL and oopses.

Check the pointer, as every other macsec_get_ops() caller already
does, and drop the frame through the existing cleanup path.

Fixes: a73d8779d61a ("net: macsec: introduce mdo_insert_tx_tag")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/net/macsec.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/net/macsec.c b/drivers/net/macsec.c
index ee0e2eb7dbc6..86c8009dcfa9 100644
--- a/drivers/net/macsec.c
+++ b/drivers/net/macsec.c
@@ -3436,6 +3436,11 @@ static struct sk_buff *macsec_insert_tx_tag(struct sk_buff *skb,
 	int err;
 
 	ops = macsec_get_ops(macsec, &ctx);
+	if (unlikely(!ops)) {
+		err = -EOPNOTSUPP;
+		goto cleanup;
+	}
+
 	skb_final_len = skb->len - ETH_HLEN + ops->needed_headroom +
 		ops->needed_tailroom;
 	if (unlikely(skb_final_len > macsec->real_dev->mtu)) {

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260805-macsec-fixes-d280baf70552

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

