From: Sven Peter <sven@kernel.org>
Date: Sun, 23 Aug 2026 18:09:19 +0200
Subject: [PATCH v2 6/7] thunderbolt: Tear down inactive DP tunnels when the
 domain is stopped
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-b4-tbt-fixes-v2-6-26a18a426c9f@kernel.org>
References: <20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org>
In-Reply-To: <20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org>
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, asahi@lists.linux.dev, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2083; i=sven@kernel.org;
 h=from:subject:message-id; bh=gM3ljiZ7OeI79gnw2yBh74ko5W+e/3qUprdtBSuU7QU=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1a3dNJ3hvKdM2vehJtY7ggJibjsWzBlSvrhTIGrAef7O
 xVE6k53lLIwiHExyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACZyeRXDX9Gku7ODwj1fHXH/
 sbzpU+SdK/YvFOL6bmudKHuV0sp0m5vhr4zU/8mztE4UTdnjfJ3t5KPH3RWGv6Lipm6aVPnoini
 JLi8A
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tb_stop only tears down DMA tunnels so a DP tunnel that is still
waiting for dprx_work to complete keeps that work queued while the
routers are removed and the control channel is stopped. The work only
stops once the DPRX timeout has passed and because it requeues itself
until then the flush_workqueue in tb_domain_remove won't wait for its
final run. The callback then runs against a domain that is already torn
down. A reference to that domain is kept so the completion waiting for
that domain to disappear in unbind will block until the timeout is
eventually reached.

Tear down DP tunnels that are not active yet as well which also cancels
that work. Tunnels for displays that are already alive are untouched and
keep working.

Fixes: d6d458d42e1e ("thunderbolt: Handle DisplayPort tunnel activation asynchronously")
Cc: stable@vger.kernel.org
Signed-off-by: Sven Peter <sven@kernel.org>
---
I also didn't run into this but noticed it when fixing the hop alloc thing
and think it makes sense to fix it anyway.
---
 drivers/thunderbolt/tb.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/thunderbolt/tb.c b/drivers/thunderbolt/tb.c
index 088323cd876d..921adba3544f 100644
--- a/drivers/thunderbolt/tb.c
+++ b/drivers/thunderbolt/tb.c
@@ -2958,12 +2958,14 @@ static void tb_stop(struct tb *tb)
 	/* tunnels are only present after everything has been initialized */
 	list_for_each_entry_safe(tunnel, n, &tcm->tunnel_list, list) {
 		/*
-		 * DMA tunnels require the driver to be functional so we
-		 * tear them down. Other protocol tunnels can be left
-		 * intact.
+		 * DMA tunnels and DP tunnels which are not yet active require
+		 * the driver to be functional so we tear them down.
+		 * Other protocol tunnels can be left intact.
 		 */
 		if (tb_tunnel_is_dma(tunnel))
 			tb_tunnel_deactivate(tunnel);
+		else if (tb_tunnel_is_dp(tunnel) && !tb_tunnel_is_active(tunnel))
+			tb_tunnel_deactivate(tunnel);
 		tb_tunnel_put(tunnel);
 	}
 	tb_switch_remove(tb->root_switch);

-- 
2.55.0

