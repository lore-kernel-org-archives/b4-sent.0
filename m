From: Sven Peter <sven@kernel.org>
Date: Sat, 29 Aug 2026 10:08:37 +0200
Subject: [PATCH v3 5/7] thunderbolt: Mark discovered tunnels as active
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260829-b4-tbt-fixes-v3-5-e1fab6ac54fe@kernel.org>
References: <20260829-b4-tbt-fixes-v3-0-e1fab6ac54fe@kernel.org>
In-Reply-To: <20260829-b4-tbt-fixes-v3-0-e1fab6ac54fe@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, asahi@lists.linux.dev, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1478; i=sven@kernel.org;
 h=from:subject:message-id; bh=Gf7s+iDVEY9i7s48leCOPqnKX0wFtaHwnlaLaAMjjTI=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9akyX0SGz9emhE/54XywU+PLC45Pp8cei7vwrZTqacfT
 vxzsv+ZV0cpC4MYF4OsmCLL9v32pk8evhFcuunSe5g5rEwgQxi4OAVgIs+5Gf7ZZao8ShY5GXjV
 UnDv0xMOEfFi177r+lY4MHyd5nXtnfsHhn9mc3OWS2QUuS5ap98q9eXwTc8WkeOZ/s/nztwouWt
 BXicLAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Discovered tunnels that have been activated by whatever was running
before us stay in TB_TUNNEL_INACTIVE until hibernation restore such that
anything depending on tb_tunnel_is_active() skips them. Mark them active
during discovery instead. These now also emit TUNNEL_EVENT=activated
uevents during discovery.

Fixes: d6d458d42e1e ("thunderbolt: Handle DisplayPort tunnel activation asynchronously")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/tunnel.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index 5f536635908f..3785e29cf92b 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -507,6 +507,7 @@ struct tb_tunnel *tb_tunnel_discover_pci(struct tb *tb, struct tb_port *down,
 		goto err_deactivate;
 	}
 
+	tb_tunnel_set_active(tunnel, true);
 	tb_tunnel_dbg(tunnel, "discovered\n");
 	return tunnel;
 
@@ -1671,6 +1672,7 @@ struct tb_tunnel *tb_tunnel_discover_dp(struct tb *tb, struct tb_port *in,
 
 	tb_dp_dump(tunnel);
 
+	tb_tunnel_set_active(tunnel, true);
 	tb_tunnel_dbg(tunnel, "discovered\n");
 	return tunnel;
 
@@ -2299,6 +2301,7 @@ struct tb_tunnel *tb_tunnel_discover_usb3(struct tb *tb, struct tb_port *down,
 			tb_usb3_reclaim_available_bandwidth;
 	}
 
+	tb_tunnel_set_active(tunnel, true);
 	tb_tunnel_dbg(tunnel, "discovered\n");
 	return tunnel;
 

-- 
2.55.0

