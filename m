From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Date: Fri, 13 Nov 2026 16:34:51 +0100
Subject: [PATCH 1/7] openconnect: Set protocol before obtaining the cookie
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-openconnect-gp-fixes-v1-1-1f7f6922d88f@gmail.com>
References: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
In-Reply-To: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=1759;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=B2eOoJPDN7wXiN/iF0W3kHne01yKJDfCDB/JMINC1P4=;
 b=KW2ueShkRyjnFkIucNm3yfB6r9aDchQd/sr1Ye/FRm8LjeaCdBQ+zo6UKZnwSB+P7MT967DCL
 j+4O3IbYngWCcORmo1KoFw2BXMZnd8ffVvXE2GK9qjex/ZYHHWb8hAy
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

[openconnect] Set protocol before obtaining the cookie.

OpenConnect.Protocol was only passed to the openconnect process started
after authentication. The built-in authentication done by connman-vpnd
with openconnect_obtain_cookie() therefore always used the default
AnyConnect protocol, even for GlobalProtect and Pulse/NC servers.

With a GlobalProtect gateway this sends an AnyConnect POST to the
gateway, which answers 404, and the connection can never be established
with the userpass authentication type.

Call openconnect_set_protocol() before obtaining the cookie, as the
openconnect --protocol option does.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
---
 vpn/plugins/openconnect.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/vpn/plugins/openconnect.c b/vpn/plugins/openconnect.c
index fb63a1a3..5ea12c62 100644
--- a/vpn/plugins/openconnect.c
+++ b/vpn/plugins/openconnect.c
@@ -1004,6 +1004,7 @@ static int authenticate(struct oc_private_data *data)
 	const char *cert = NULL;
 	const char *key = NULL;
 	const char *urlpath;
+	const char *protocol;
 	const char *vpnhost;
 
 	DBG("");
@@ -1036,6 +1037,13 @@ static int authenticate(struct oc_private_data *data)
 			oc_progress,
 			data);
 
+	/* Same as openconnect's --protocol, needed before obtaining the cookie */
+	protocol = vpn_provider_get_string(data->provider,
+						"OpenConnect.Protocol");
+	if (protocol && *protocol &&
+			openconnect_set_protocol(data->vpninfo, protocol))
+		connman_warn("Unsupported OpenConnect protocol %s", protocol);
+
 	/* Replicating how openconnect's --usergroup argument works */
 	urlpath = vpn_provider_get_string(data->provider,
 						"OpenConnect.Usergroup");

-- 
2.50.1

