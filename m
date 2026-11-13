From: =?utf-8?q?St=C3=A9phane_COLIN?= <bigbob.fun@gmail.com>
Date: Fri, 13 Nov 2026 16:34:52 +0100
Subject: [PATCH 2/7] openconnect: Do not treat reconnect reasons as
 disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-openconnect-gp-fixes-v1-2-1f7f6922d88f@gmail.com>
References: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
In-Reply-To: <20261113-openconnect-gp-fixes-v1-0-1f7f6922d88f@gmail.com>
To: connman@lists.linux.dev
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794584090; l=1525;
 i=bigbob.fun@gmail.com; s=20261113; h=from:subject:message-id;
 bh=h8wCuXfu5LBZiPAFN7yuQFV+dbuBM65vaTOmx5XuB0w=;
 b=+PbEDTbxNakDh3cLgOwSwS0bxDEXPYUwbcuFtNLWEkrPlOab2GYxf8LbNkjRJLMhAr7HDxCIr
 JipgzeI2skhBoEenpHX98b+sveU5capAjMHE86+HebuQ8M78fTAmLnH
X-Developer-Key: i=bigbob.fun@gmail.com; a=ed25519;
 pk=MoY1DAn0hlhveZhsN9JyLnuWS/CGqJHTad4MaTL8HgY=
X-Endpoint-Received: by B4 Relay for bigbob.fun@gmail.com/20261113 with auth_id=1512
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

[openconnect] Do not treat reconnect reasons as disconnect.

When the connection is interrupted, e.g. after the device has been
suspended, openconnect keeps the tun device and reconnects by itself.
It calls the vpnc-script with the "attempt-reconnect" and "reconnect"
reasons, but oc_notify() handles every reason other than "connect" as
VPN_STATE_DISCONNECT.

As a result connman-vpnd tears the provider down while openconnect is
still running: the tunnel is lost, the openconnect process is left
orphaned and the UI stays in the "Disconnecting" state.

Return VPN_STATE_UNKNOWN for these two reasons so that the state is
kept as is while openconnect reconnects.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
---
 vpn/plugins/openconnect.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/vpn/plugins/openconnect.c b/vpn/plugins/openconnect.c
index 5ea12c62..4585d785 100644
--- a/vpn/plugins/openconnect.c
+++ b/vpn/plugins/openconnect.c
@@ -292,6 +292,15 @@ static int oc_notify(DBusMessage *msg, struct vpn_provider *provider)
 		return VPN_STATE_FAILURE;
 	}
 
+	/*
+	 * openconnect keeps the tunnel up while it reconnects (e.g. after the
+	 * device has been suspended) and reports it with these two reasons.
+	 * They must not be treated as a disconnect.
+	 */
+	if (!strcmp(reason, "attempt-reconnect") ||
+				!strcmp(reason, "reconnect"))
+		return VPN_STATE_UNKNOWN;
+
 	if (strcmp(reason, "connect"))
 		return VPN_STATE_DISCONNECT;
 

-- 
2.50.1

