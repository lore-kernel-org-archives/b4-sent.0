From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Date: Fri, 13 Nov 2026 16:34:56 +0100
Subject: [PATCH 6/7] openconnect: Do not take _MASKLEN for _MASK in split
 routes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-openconnect-gp-fixes-v1-6-1f7f6922d88f@gmail.com>
References: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
In-Reply-To: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=1287;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=QZ8vedk6HgQFH3L8Fjs7zuQ1HtVz3MBoj3nizmjgk7g=;
 b=AIPHSIV5g8xRn4ibUefkGDGJcoi5oAVpp+xEnSjThggCjpnxSn8T9tyOmeWKN4bOTKEOVZeuY
 4Pj24t5lmngBER8z2814rq0+aqhvS454L4UzqbQiM/hGtQ9wb4ofMm0
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

oc_route_env_parse() tested "_MASK" with strncmp() before "_MASKLEN",
so CISCO_SPLIT_INC_n_MASKLEN also matched and, depending on the order of
the environment, the IPv4 dotted netmask was replaced by the prefix
length that connmand then passed to inet_addr().

Compare the suffixes exactly: _MASK for IPv4, _MASKLEN for IPv6.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
---
 vpn/plugins/openconnect.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/vpn/plugins/openconnect.c b/vpn/plugins/openconnect.c
index 7901a8d7..876d4142 100644
--- a/vpn/plugins/openconnect.c
+++ b/vpn/plugins/openconnect.c
@@ -1831,11 +1831,11 @@ static int oc_route_env_parse(struct vpn_provider *provider, const char *key,
 
 	*idx = g_ascii_strtoull(start, &end, 10);
 
-	if (strncmp(end, "_ADDR", 5) == 0)
+	if (strcmp(end, "_ADDR") == 0)
 		*type = VPN_PROVIDER_ROUTE_TYPE_ADDR;
-	else if (strncmp(end, "_MASK", 5) == 0)
+	else if (strcmp(end, "_MASKLEN") == 0 && *family == AF_INET6)
 		*type = VPN_PROVIDER_ROUTE_TYPE_MASK;
-	else if (strncmp(end, "_MASKLEN", 8) == 0 && *family == AF_INET6)
+	else if (strcmp(end, "_MASK") == 0 && *family == AF_INET)
 		*type = VPN_PROVIDER_ROUTE_TYPE_MASK;
 	else
 		return -EINVAL;

-- 
2.50.1

