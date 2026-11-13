From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Date: Fri, 13 Nov 2026 16:34:54 +0100
Subject: [PATCH 4/7] openconnect: Limit repeated credential forms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-openconnect-gp-fixes-v1-4-1f7f6922d88f@gmail.com>
References: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
In-Reply-To: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=2237;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=mUj9AmNEhvJsj6vIuOhSebdh13ZYfRNcPvX+3ApgS0M=;
 b=erDPVwViBUCM/9/dMUiG8EO9WdzmJNEWMiirokedV0ZHH4fTsn40u01OCIcb4GYxr2HcxgDyk
 aE1YHzROY98DXVr5WySBiPJKNsJS5XbJvwpkINMF7wb9mayXEMzO+r5
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

[openconnect] Limit repeated credential forms.

With the userpass authentication types the same stored credentials are
submitted every time the server sends the login form again. When the
server rejects them, connman-vpnd keeps resubmitting them in a tight
loop (about 50 attempts were seen against a GlobalProtect gateway),
which may lock the account.

Give up after OC_MAX_USERPASS_FORMS (3) forms: report an authentication
failure and clear the stored credentials so that the user is asked for
them again on the next attempt.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
---
 vpn/plugins/openconnect.c | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/vpn/plugins/openconnect.c b/vpn/plugins/openconnect.c
index 03adf9bf..7901a8d7 100644
--- a/vpn/plugins/openconnect.c
+++ b/vpn/plugins/openconnect.c
@@ -92,6 +92,8 @@ enum oc_connect_type {
 static const char *connect_types[] = {"cookie", "cookie_with_userpass",
 			"userpass", "publickey", "pkcs", NULL};
 
+#define OC_MAX_USERPASS_FORMS 3
+
 struct oc_private_data {
 	struct vpn_provider *provider;
 	struct connman_task *task;
@@ -111,6 +113,7 @@ struct oc_private_data {
 	enum oc_connect_type connect_type;
 	bool tried_passphrase;
 	bool group_set;
+	int userpass_forms;
 };
 
 typedef void (*request_input_reply_cb_t) (DBusMessage *reply,
@@ -848,6 +851,22 @@ static gboolean process_auth_form(void *user_data)
 	switch (data->connect_type) {
 	case OC_CONNECT_USERPASS:
 	case OC_CONNECT_COOKIE_WITH_USERPASS:
+		/*
+		 * The same stored credentials are submitted every time the
+		 * server sends the form again. Stop after a few rounds so that
+		 * rejected credentials do not hammer the server (and lock the
+		 * account) in a tight loop.
+		 */
+		if (++data->userpass_forms > OC_MAX_USERPASS_FORMS) {
+			connman_warn("Credentials rejected %d times, giving up",
+						OC_MAX_USERPASS_FORMS);
+			vpn_provider_add_error(data->provider,
+					VPN_PROVIDER_ERROR_AUTH_FAILED);
+			clear_provider_credentials(data->provider, true);
+			data->err = -EACCES;
+			form_data->status = OC_FORM_RESULT_ERR;
+			goto out;
+		}
 		break;
 
 	case OC_CONNECT_PKCS:

-- 
2.50.1

