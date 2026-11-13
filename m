From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Date: Fri, 13 Nov 2026 16:34:53 +0100
Subject: [PATCH 3/7] openconnect: Fill the GlobalProtect "passwd" form
 field
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-openconnect-gp-fixes-v1-3-1f7f6922d88f@gmail.com>
References: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
In-Reply-To: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=1136;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=fjQR+ao1UtzVB/b/9INjX1ZWPyBqc18L/LG296YWuSM=;
 b=8D0A/gOmfLIpMzwG1GRQ2grbHUThkRjeB5CjXlLO41z3rjICjhur35MOUlUPM/B/A5IFP14Jg
 WFXdHd77TDmAawOToBLRGfMjVaLoZaMQaWi9cxglviEsaE4+E3HPQJM
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

[openconnect] Fill the GlobalProtect "passwd" form field.

process_auth_form() only fills password fields whose name starts with
"password". The GlobalProtect login form names its password field
"passwd", so it was left empty and the server rejected the login with
an empty password, again and again.

Also fill a password field named "passwd".

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
---
 vpn/plugins/openconnect.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/vpn/plugins/openconnect.c b/vpn/plugins/openconnect.c
index 4585d785..03adf9bf 100644
--- a/vpn/plugins/openconnect.c
+++ b/vpn/plugins/openconnect.c
@@ -917,7 +917,9 @@ static gboolean process_auth_form(void *user_data)
 			if (user)
 				opt->_value = strdup(user);
 		} else if (opt->type == OC_FORM_OPT_PASSWORD &&
-				g_str_has_prefix(opt->name, "password")) {
+				(g_str_has_prefix(opt->name, "password") ||
+				!g_strcmp0(opt->name, "passwd"))) {
+			/* GlobalProtect names the password field "passwd" */
 
 			const char *pass = vpn_provider_get_string(
 						data->provider,

-- 
2.50.1

