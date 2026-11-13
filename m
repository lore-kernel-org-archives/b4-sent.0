From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Date: Fri, 13 Nov 2026 16:34:55 +0100
Subject: [PATCH 5/7] vpn-provider: Signal routes without gateway
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-openconnect-gp-fixes-v1-5-1f7f6922d88f@gmail.com>
References: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
In-Reply-To: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=1298;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=RzDvYQdf2sJ/hchp5S6KtuhyCFEUNm7OdvGDxv1QMfw=;
 b=/LT7/bhaX5/QVPlYhgbDv/ei51lF8Su6mfd1sOJSCybuiFZON5LzCzlFln+e5I0mEJ9DyHLsq
 1yMu/2Er7aYBAiuB/sRCgoeswuAxPc+F9l+12qjccJtShJMv3TJS+Oi
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split routes pushed to openconnect (CISCO_SPLIT_INC_n_ADDR/_MASK) have
no gateway, so vpn_provider_append_route() never scheduled the
ServerRoutes change and connmand, which ignores ServerRoutes when
reading the initial connection properties, never installed them. A
split tunnel then either sent all IPv4 through the VPN default route
(SplitRouting false) or could not reach the VPN networks at all
(SplitRouting true).

Signal the route as soon as it has a network and a netmask, the
gateway being optional.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
---
 vpn/vpn-provider.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/vpn/vpn-provider.c b/vpn/vpn-provider.c
index dafdaffa..e8e24a9f 100644
--- a/vpn/vpn-provider.c
+++ b/vpn/vpn-provider.c
@@ -3158,7 +3158,12 @@ int vpn_provider_append_route(struct vpn_provider *provider,
 		break;
 	}
 
-	if (route->netmask && route->gateway && route->network)
+	/*
+	 * Gateway is optional: split routes of e.g. openconnect
+	 * (CISCO_SPLIT_INC_*) have only address and netmask and must still
+	 * be signaled as ServerRoutes, otherwise connmand never adds them.
+	 */
+	if (route->netmask && route->network)
 		provider_schedule_changed(provider);
 
 	return 0;

-- 
2.50.1

