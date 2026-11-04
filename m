From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 09:37:29 -0600
Subject: [PATCH] Leave a control interface directory without permission to
 remove it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b136-ctrl-dir-permission-v1-1-0204f87a5a87@gmail.com>
X-B4-Tracking: v=1; b=H4sIADhR62oC/yXMQQqDQAxA0atI1g1MpuqAV5EudIwaaVUSWwri3
 Tva5Vv8v4OxChtU2Q7KHzFZ5gS6ZRDHZh4YpUsG73xJ5HJs6V5i3PSJnSiurC+xM8ImFCF4F3M
 qHKR8Ve7le63rx9/2bieO2/mD4/gBS33lO3wAAAA=
X-Change-ID: 20261104-b136-ctrl-dir-permission-a757720c4150
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793806648; l=4131;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=lriSP7PyB5bJMolvfeRIwu2NEfGhsgm3cF1GsJ8UTSg=;
 b=qY0urMj8K9NpvRxoCpzst0xizuLnIDR65hy7mfyE7df0vBW9sK4z6Cwph4Dkwvm4c1FnRGBl0
 Bqt0ija7IqHDH+sS6oivwAc9TZcwmM6MCYxDgDSUyfK4X40aS6G2XTe
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hostapd and wpa_supplicant try to remove their control interface
directory when the last interface using it goes away, and report any
failure other than ENOTEMPTY as an error. A process that dropped its
privileges, as OpenWrt runs both (user network, in a jail), cannot
remove a directory that was created for it in a root-owned parent
(/var/run/hostapd), so every time the last interface goes it logs

  rmdir[ctrl_interface=/var/run/hostapd]: Permission denied

The directory is not this process's to remove, as when it is not empty:
treat EACCES and EPERM the same way, at debug level, with the reason.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Tested on OpenWrt (hostapd jailed as user network) on an Arista W-118,
with the change as a package patch: removing the last BSS logged the
rmdir error before, and nothing at error level after.
---
 hostapd/ctrl_iface.c             | 24 ++++++++++++++----------
 wpa_supplicant/ctrl_iface_unix.c |  9 +++++----
 2 files changed, 19 insertions(+), 14 deletions(-)

diff --git a/hostapd/ctrl_iface.c b/hostapd/ctrl_iface.c
index c53e33b..0a683d7 100644
--- a/hostapd/ctrl_iface.c
+++ b/hostapd/ctrl_iface.c
@@ -5260,9 +5260,11 @@ void hostapd_mld_ctrl_iface_deinit(struct hostapd_mld *mld)
 
 		if (mld->ctrl_interface &&
 		    rmdir(mld->ctrl_interface) < 0) {
-			if (errno == ENOTEMPTY) {
+			if (errno == ENOTEMPTY || errno == EACCES ||
+			    errno == EPERM) {
 				wpa_printf(MSG_DEBUG,
-					   "MLD control interface directory not empty - leaving it behind");
+					   "MLD control interface directory %s not removed (%s) - leaving it behind",
+					   mld->ctrl_interface, strerror(errno));
 			} else {
 				wpa_printf(MSG_ERROR,
 					   "rmdir[ctrl_interface=%s]: %s",
@@ -5608,10 +5610,11 @@ void hostapd_ctrl_iface_deinit(struct hostapd_data *hapd)
 
 		if (hapd->conf->ctrl_interface &&
 		    rmdir(hapd->conf->ctrl_interface) < 0) {
-			if (errno == ENOTEMPTY) {
-				wpa_printf(MSG_DEBUG, "Control interface "
-					   "directory not empty - leaving it "
-					   "behind");
+			if (errno == ENOTEMPTY || errno == EACCES ||
+			    errno == EPERM) {
+				wpa_printf(MSG_DEBUG,
+					   "Control interface directory %s not removed (%s) - leaving it behind",
+					   hapd->conf->ctrl_interface, strerror(errno));
 			} else {
 				wpa_printf(MSG_ERROR,
 					   "rmdir[ctrl_interface=%s]: %s",
@@ -6399,10 +6402,11 @@ void hostapd_global_ctrl_iface_deinit(struct hapd_interfaces *interfaces)
 
 		if (interfaces->global_iface_path &&
 		    rmdir(interfaces->global_iface_path) < 0) {
-			if (errno == ENOTEMPTY) {
-				wpa_printf(MSG_DEBUG, "Control interface "
-					   "directory not empty - leaving it "
-					   "behind");
+			if (errno == ENOTEMPTY || errno == EACCES ||
+			    errno == EPERM) {
+				wpa_printf(MSG_DEBUG,
+					   "Control interface directory %s not removed (%s) - leaving it behind",
+					   interfaces->global_iface_path, strerror(errno));
 			} else {
 				wpa_printf(MSG_ERROR,
 					   "rmdir[ctrl_interface=%s]: %s",
diff --git a/wpa_supplicant/ctrl_iface_unix.c b/wpa_supplicant/ctrl_iface_unix.c
index 6f5991a..0fa6c88 100644
--- a/wpa_supplicant/ctrl_iface_unix.c
+++ b/wpa_supplicant/ctrl_iface_unix.c
@@ -890,10 +890,11 @@ void wpa_supplicant_ctrl_iface_deinit(struct wpa_supplicant *wpa_s,
 			dir = buf;
 
 		if (rmdir(dir) < 0) {
-			if (errno == ENOTEMPTY) {
-				wpa_printf(MSG_DEBUG, "Control interface "
-					   "directory not empty - leaving it "
-					   "behind");
+			if (errno == ENOTEMPTY || errno == EACCES ||
+			    errno == EPERM) {
+				wpa_printf(MSG_DEBUG,
+					   "Control interface directory %s not removed (%s) - leaving it behind",
+					   dir, strerror(errno));
 			} else {
 				wpa_printf(MSG_ERROR,
 					   "rmdir[ctrl_interface=%s]: %s",

---
base-commit: 412ff0d7f4d2b346df63be52c4201ee7ab0dc804
change-id: 20261104-b136-ctrl-dir-permission-a757720c4150

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

