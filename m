From: Miao Wang <shankerwangmiao@gmail.com>
Date: Thu, 17 Jul 2025 16:27:37 +0800
Subject: [PATCH iptables v2] extensions: libebt_redirect: prevent
 translation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250717-xlat-ebt-redir-v2-1-74fe39757369@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPizeGgC/3WNywqDMBBFf0Vm3SkmNVK76n8UF6OOOuCLJASL5
 N8bsu/ycLjnXuDYCjt4FRdYDuJk3xLoWwH9TNvEKENi0KU2ZaUNngt55M6j5UEsElVlo59jPRJ
 DGh2WRzlz8ANyeOqWBG0yszi/229+Cir7f9GgUOGDlSLTaGPq5j2tJMu931doY4w/pv0ntLYAA
 AA=
X-Change-ID: 20250425-xlat-ebt-redir-aa40928f6fae
To: netfilter-devel@vger.kernel.org
Cc: Pablo Neira Ayuso <pablo@netfilter.org>, phil@nwl.cc, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3134;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=TSPPr1F5AtRVaecHZO/IgT4eoPQHgBuUtWAoAvnRlGs=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBoeLP8wEE0c/18izVGT+LDndfeDnTPbTkhJXLOY
 6r9mgt9qWCJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCaHiz/AAKCRCwMePKe/7Z
 blzVEADaTNNkrjjlmoLHx4ANUo2XnIuZlp0ddWP2gHkRNcus1wfvt5CnxMTggSIVP8nX7gjOzCb
 yEeImIdTZ4loVn+onfBA+s6WjzeBEu36bN+nV4iV6r/GACmqO3FU+8TS6fQQZu5pRWg5O0S8VA2
 AsPrCvfbvB/DQMZr6/lGVrbubFfU1W5IM7V6AWfGj9Gn4Ebwz3zCNd6j3UoRXCb4UcncgCfPKtP
 c5NTqWWaK3r1PqnKbUNEOTtjEHKJK06SdPzdro45sl3D/f3T/DKBc/ORDJ/b0155eW8pmFrAly5
 gaXbrBNmiB/DpJWnrtc4U72lVYhF5pa9GDWGCGes8QipEK5Lm+67I7HvHDs0Z+deSCA/lkYV6cC
 shi3wWyaXcaiTaMRqcht37EqPQJxhXh+jyuOBy6G9YF1rRYyB8pq9+Djq/YpJK80Wzcn9Axw96V
 i+KPHQjTOp6kGwtSJlmVPUwDORXDN+EDXXFKtk3ookbkq4HxHoiDfkoBEwBhkCQi0H9M748dlOm
 OTVxNOgcu9tfqTANuOwRIli3Dwn/13FKR5u14HjBXV8Dq2i17i8ZsuLuvocFkKbbFV0Nq8riKDK
 yAnpmwsP+GqxJQGo27MS0Y9SZQUjkunDglPadssMfCGgQa+qV5IdBCzv0Mivy1zDUN4f1pGsFHb
 eJDRC3gxOZBPl4g==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The redirect target in ebtables do two things: 1. set skb->pkt_type to
PACKET_HOST, and 2. set the destination mac address to the address of
the receiving bridge device (when not used in BROUTING chain), or the
receiving physical device (otherwise). However, the later cannot be
implemented in nftables not given the translated mac address. So it is
not appropriate to give a specious translation.

This patch disables the translation to prevent possible misunderstanding.

Fixes: 24ce7465056ae ("ebtables-compat: add redirect match extension")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v2:
- Completely remove the translation from the ebtables redirect target to
  nft rule according to Pablo's suggestion.
- Link to v1: https://lore.kernel.org/r/20250425-xlat-ebt-redir-v1-1-3e11a5925569@gmail.com
---
 extensions/libebt_redirect.c      | 19 +------------------
 extensions/libebt_redirect.txlate |  8 --------
 2 files changed, 1 insertion(+), 26 deletions(-)

diff --git a/extensions/libebt_redirect.c b/extensions/libebt_redirect.c
index a44dbaec6cc8b12f20acd31dcb1360ac7245e349..12d87f93df6386cacf4fe257070933cc552b41f4 100644
--- a/extensions/libebt_redirect.c
+++ b/extensions/libebt_redirect.c
@@ -60,27 +60,10 @@ static void brredir_print(const void *ip, const struct xt_entry_target *target,
 	printf("--redirect-target %s", ebt_target_name(redirectinfo->target));
 }
 
-static const char* brredir_verdict(int verdict)
-{
-	switch (verdict) {
-	case EBT_ACCEPT: return "accept";
-	case EBT_DROP: return "drop";
-	case EBT_CONTINUE: return "continue";
-	case EBT_RETURN: return "return";
-	}
-
-	return "";
-}
-
 static int brredir_xlate(struct xt_xlate *xl,
 			 const struct xt_xlate_tg_params *params)
 {
-	const struct ebt_redirect_info *red = (const void*)params->target->data;
-
-	xt_xlate_add(xl, "meta pkttype set host");
-	if (red->target != EBT_CONTINUE)
-		xt_xlate_add(xl, " %s ", brredir_verdict(red->target));
-	return 1;
+	return 0;
 }
 
 static struct xtables_target brredirect_target = {
diff --git a/extensions/libebt_redirect.txlate b/extensions/libebt_redirect.txlate
deleted file mode 100644
index d073ec774c4fa817e48422fb99aaf095dd9eab65..0000000000000000000000000000000000000000
--- a/extensions/libebt_redirect.txlate
+++ /dev/null
@@ -1,8 +0,0 @@
-ebtables-translate -t nat -A PREROUTING -d de:ad:00:00:be:ef -j redirect
-nft 'add rule bridge nat PREROUTING ether daddr de:ad:00:00:be:ef counter meta pkttype set host accept'
-
-ebtables-translate -t nat -A PREROUTING -d de:ad:00:00:be:ef -j redirect --redirect-target RETURN
-nft 'add rule bridge nat PREROUTING ether daddr de:ad:00:00:be:ef counter meta pkttype set host return'
-
-ebtables-translate -t nat -A PREROUTING -d de:ad:00:00:be:ef -j redirect --redirect-target CONTINUE
-nft 'add rule bridge nat PREROUTING ether daddr de:ad:00:00:be:ef counter meta pkttype set host'

---
base-commit: 192c3a6bc18f206895ec5e38812d648ccfe7e281
change-id: 20250425-xlat-ebt-redir-aa40928f6fae

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

