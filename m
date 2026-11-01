From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 12:59:28 -0600
Subject: [PATCH] FT: Answer a repeated FT Authentication Request with the
 same response
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b95-ft-repeated-auth-v1-1-27e1a0d4e36d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAA+M52oC/yXMSwqDMBRG4a3IHfdCErRit1I6SOJvvR2o5CGCu
 HejHX6Dc3aKCIJIr2qngFWizFOBflTkRzt9wdIXk1HmqbXS7LqGh8QBC2xCzzankZUzrWobD4+
 aSroEDLLd2/fn75jdDz5dLzqOE8Vvnbd4AAAA
X-Change-ID: 20261101-b95-ft-repeated-auth-0b27075cece4
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793559567; l=7345;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=wP2mXNCiHjFjaGGWl/S3MSRCvCZ+CAJGNs5dsbAhxSo=;
 b=L4LRsE8kvTjIYu5eeEw+RW5XUQEgvHyG22mid8etk7nCsBDnBPKh1FagG7JqpugEZjoGGlvO/
 yPbIcySig/zCvXQQzyuZhXBr/8fPo689y7EXi18qynYXLmnK0A3Io8Y
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A STA that gets no FT Authentication Response in time sends its request
again, as a new frame: mac80211 retransmits it 100 ms after the AP
acknowledged it without answering. hostapd takes the repeat for a new
exchange: it draws a new ANonce, derives a new PTK and installs it. If
the STA goes on with the response to its first request, its
Reassociation Request carries the first ANonce while hostapd has the
second, and hostapd refuses it with status 55 (Invalid FTE, ANonce
mismatch). The STA gets on only after a new exchange.

An AP that is slow to answer makes this common. One such case is a STA
that roams back to an AP that still has it as associated without PMF:
the response waits until hostapd has removed the STA from the driver
and added it again. On OpenWrt APs about 5% of FT roams back to the AP
a STA had just left were refused with status 55, after an Authentication
frame retransmission, on FT-SAE and FT-EAP.

Reproduced with two FT-PSK BSSes on one ath10k radio and a mac80211
STA, with hostapd stopped for 400 ms as the STA started the roam: every
roam where the STA retransmitted its request was refused with status 55
(5 of 5). With this change, 10 of 10 such roams completed, with one PTK
installation each.

Keep the last FT Authentication Request and its successful response per
STA, and answer an identical request with the same response, without
deriving or installing anything. Forget them on any WPA state machine
event except the FT reassociation that completes the exchange, so that
a late copy of a completed request does not install a new PTK either.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen on OpenWrt APs (ath11k, mt76) running hostapd with FT-SAE and FT-EAP;
reproduced and tested on an Arista W-118 (ath10k).
---
 src/ap/wpa_auth.c    |  9 +++++++++
 src/ap/wpa_auth_ft.c | 49 ++++++++++++++++++++++++++++++++++++++++++++++++-
 src/ap/wpa_auth_i.h  |  3 +++
 3 files changed, 60 insertions(+), 1 deletion(-)

diff --git a/src/ap/wpa_auth.c b/src/ap/wpa_auth.c
index 2c8c743..5b10a62 100644
--- a/src/ap/wpa_auth.c
+++ b/src/ap/wpa_auth.c
@@ -1202,6 +1202,7 @@ static void wpa_free_sta_sm(struct wpa_state_machine *sm)
 #ifdef CONFIG_IEEE80211R_AP
 	os_free(sm->assoc_resp_ftie);
 	wpabuf_free(sm->ft_pending_req_ies);
+	wpa_ft_auth_forget(sm);
 #endif /* CONFIG_IEEE80211R_AP */
 	os_free(sm->last_rx_eapol_key);
 	os_free(sm->wpa_ie);
@@ -2484,6 +2485,14 @@ int wpa_auth_sm_event(struct wpa_state_machine *sm, enum wpa_event event)
 	wpa_auth_vlogger(sm->wpa_auth, wpa_auth_get_spa(sm), LOGGER_DEBUG,
 			 "event %d notification", event);
 
+#ifdef CONFIG_IEEE80211R_AP
+	/* After anything but the reassociation that completes it, a later FT
+	 * Authentication Request starts a new exchange. A late copy of the
+	 * completed one still gets its response and changes nothing. */
+	if (event != WPA_ASSOC_FT)
+		wpa_ft_auth_forget(sm);
+#endif /* CONFIG_IEEE80211R_AP */
+
 	switch (event) {
 	case WPA_AUTH:
 #ifdef CONFIG_MESH
diff --git a/src/ap/wpa_auth_ft.c b/src/ap/wpa_auth_ft.c
index e12f2ad..551af5b 100644
--- a/src/ap/wpa_auth_ft.c
+++ b/src/ap/wpa_auth_ft.c
@@ -3426,6 +3426,29 @@ out:
 }
 
 
+void wpa_ft_auth_forget(struct wpa_state_machine *sm)
+{
+	wpabuf_free(sm->ft_auth_req);
+	sm->ft_auth_req = NULL;
+	wpabuf_free(sm->ft_auth_resp);
+	sm->ft_auth_resp = NULL;
+}
+
+
+static void wpa_ft_auth_remember(struct wpa_state_machine *sm,
+				 const u8 *req, size_t req_len, u16 status,
+				 const u8 *resp, size_t resp_len)
+{
+	wpa_ft_auth_forget(sm);
+	if (status != WLAN_STATUS_SUCCESS)
+		return;
+	sm->ft_auth_req = wpabuf_alloc_copy(req, req_len);
+	sm->ft_auth_resp = wpabuf_alloc_copy(resp, resp_len);
+	if (!sm->ft_auth_req || !sm->ft_auth_resp)
+		wpa_ft_auth_forget(sm);
+}
+
+
 void wpa_ft_process_auth(struct wpa_state_machine *sm,
 			 u16 auth_transaction, const u8 *ies, size_t ies_len,
 			 void (*cb)(void *ctx, const u8 *dst,
@@ -3452,6 +3475,26 @@ void wpa_ft_process_auth(struct wpa_state_machine *sm,
 	sm->ft_pending_cb_ctx = ctx;
 	sm->ft_pending_auth_transaction = auth_transaction;
 	sm->ft_pending_pull_left_retries = sm->wpa_auth->conf.rkh_pull_retries;
+
+	/*
+	 * A STA that got no response in time sends the same request again,
+	 * as a new frame. It may then go on with the response to either, so
+	 * answer a repeat with the same response: a new ANonce and PTK would
+	 * make the Reassociation Request that follows the first response fail
+	 * with an ANonce mismatch, and would replace the PTK in the driver.
+	 */
+	if (sm->ft_auth_req && wpabuf_len(sm->ft_auth_req) == ies_len &&
+	    os_memcmp(wpabuf_head(sm->ft_auth_req), ies, ies_len) == 0) {
+		wpa_printf(MSG_DEBUG,
+			   "FT: Repeated authentication request from " MACSTR
+			   " - send the same response again",
+			   MAC2STR(sm->addr));
+		cb(ctx, sm->addr, auth_transaction + 1, WLAN_STATUS_SUCCESS,
+		   wpabuf_head(sm->ft_auth_resp),
+		   wpabuf_len(sm->ft_auth_resp));
+		return;
+	}
+
 	res = wpa_ft_process_auth_req(sm, ies, ies_len, &resp_ies,
 				      &resp_ies_len);
 	if (res < 0) {
@@ -3459,6 +3502,7 @@ void wpa_ft_process_auth(struct wpa_state_machine *sm,
 		return;
 	}
 	status = res;
+	wpa_ft_auth_remember(sm, ies, ies_len, status, resp_ies, resp_ies_len);
 
 	wpa_printf(MSG_DEBUG, "FT: FT authentication response: dst=" MACSTR
 		   " auth_transaction=%d status=%u (%s)",
@@ -4317,9 +4361,12 @@ static void ft_finish_pull(struct wpa_state_machine *sm)
 			   "FT: Callback postponed until response is available");
 		return;
 	}
+	status = res;
+	wpa_ft_auth_remember(sm, wpabuf_head(sm->ft_pending_req_ies),
+			     wpabuf_len(sm->ft_pending_req_ies), status,
+			     resp_ies, resp_ies_len);
 	wpabuf_free(sm->ft_pending_req_ies);
 	sm->ft_pending_req_ies = NULL;
-	status = res;
 	wpa_printf(MSG_DEBUG, "FT: Postponed auth callback result for " MACSTR
 		   " - status %u", MAC2STR(sm->addr), status);
 
diff --git a/src/ap/wpa_auth_i.h b/src/ap/wpa_auth_i.h
index b80e9bd..52d1d08 100644
--- a/src/ap/wpa_auth_i.h
+++ b/src/ap/wpa_auth_i.h
@@ -149,6 +149,8 @@ struct wpa_state_machine {
 			      const u8 *ies, size_t ies_len);
 	void *ft_pending_cb_ctx;
 	struct wpabuf *ft_pending_req_ies;
+	struct wpabuf *ft_auth_req; /* last FT Authentication Request */
+	struct wpabuf *ft_auth_resp; /* and its successful response */
 	u8 ft_pending_pull_nonce[FT_RRB_NONCE_LEN];
 	u8 ft_pending_auth_transaction;
 	u8 ft_pending_current_ap[ETH_ALEN];
@@ -356,6 +358,7 @@ void wpa_auth_ft_store_keys(struct wpa_state_machine *sm, const u8 *pmk_r0,
 struct wpa_ft_pmk_cache * wpa_ft_pmk_cache_init(void);
 void wpa_ft_pmk_cache_deinit(struct wpa_ft_pmk_cache *cache);
 void wpa_ft_install_ptk(struct wpa_state_machine *sm, int retry);
+void wpa_ft_auth_forget(struct wpa_state_machine *sm);
 int wpa_ft_store_pmk_fils(struct wpa_state_machine *sm, const u8 *pmk_r0,
 			  const u8 *pmk_r0_name);
 #endif /* CONFIG_IEEE80211R_AP */

---
base-commit: 1f2231a88a742befbea44bc19ffee94bed616505
change-id: 20261101-b95-ft-repeated-auth-0b27075cece4

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

