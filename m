From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Date: Fri, 13 Nov 2026 16:34:57 +0100
Subject: [PATCH 7/7] openconnect: Offer the username again on the next
 login
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-openconnect-gp-fixes-v1-7-1f7f6922d88f@gmail.com>
References: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
In-Reply-To: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=2709;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=KBSqCdQfMpgssekgPPwFWdPoKYC0mjws6mr/VymvQzs=;
 b=8YgL+UXWU9hsM4gHf/tIkZRVUxF2ncaMjYvEPL9SFfWAdqx5vCUegpxg4Mj9kvfvDQimmR515
 xC5RPZShLo1ADaPiMfiT6/QIwbPi8albV8HluwRo/fWf9VZKeNvSIRs
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The username was never pre-filled in the credentials dialog: the plugin
passed the username value to vpn_agent_append_user_info(), which expects
the provider key, and the username was cleared to "-" together with the
password after every connection attempt. Once the cookie had expired
(e.g. after the VPN was fully down for the night), the user had to type
it again.

Keep the username when the credentials are cleared, give the key to
vpn_agent_append_user_info() and do not offer the "-" placeholder as a
value. Password and cookie are still cleared as before. The username is
kept in memory only; persisting it is left to the VPN agent.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
---
 vpn/plugins/openconnect.c | 7 +++----
 vpn/vpn-agent.c           | 3 ++-
 2 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/vpn/plugins/openconnect.c b/vpn/plugins/openconnect.c
index 876d4142..b8cd3aab 100644
--- a/vpn/plugins/openconnect.c
+++ b/vpn/plugins/openconnect.c
@@ -483,8 +483,8 @@ static bool strv_contains_prefix(const char *strv[], const char *str)
 static void clear_provider_credentials(struct vpn_provider *provider,
 						bool clear_pkcs_pass)
 {
+	/* The username is kept: it is offered again on the next login */
 	const char *keys[] = { "OpenConnect.PKCSPassword",
-				"OpenConnect.Username",
 				"OpenConnect.Password",
 				"OpenConnect.SecondPassword",
 				"OpenConnect.Cookie",
@@ -1465,7 +1465,6 @@ static int request_input_credentials_full(
 	const char *path;
 	const char *agent_sender;
 	const char *agent_path;
-	const char *username;
 	DBusMessageIter iter;
 	DBusMessageIter dict;
 	int err;
@@ -1534,9 +1533,9 @@ static int request_input_credentials_full(
 	case OC_CONNECT_COOKIE_WITH_USERPASS:
 		/* fallthrough */
 	case OC_CONNECT_USERPASS:
-		username = vpn_provider_get_string(data->provider,
+		/* The key of the username, not its value */
+		vpn_agent_append_user_info(&dict, data->provider,
 					"OpenConnect.Username");
-		vpn_agent_append_user_info(&dict, data->provider, username);
 
 		use_second_password = vpn_provider_get_boolean(data->provider,
 					"OpenConnect.UseSecondPassword",
diff --git a/vpn/vpn-agent.c b/vpn/vpn-agent.c
index ab6fea55..e58bf2eb 100644
--- a/vpn/vpn-agent.c
+++ b/vpn/vpn-agent.c
@@ -123,7 +123,8 @@ static void request_input_append_user_info(DBusMessageIter *iter,
 
 	if (data->username_str) {
 		str = vpn_provider_get_string(provider, data->username_str);
-		if (str)
+		/* "-" means cleared */
+		if (str && *str && g_strcmp0(str, "-"))
 			connman_dbus_dict_append_basic(iter, "Value",
 						DBUS_TYPE_STRING, &str);
 	}

-- 
2.50.1

