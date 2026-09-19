From: Ilyas <ilyas.tasli@outlook.fr>
Date: Sat, 19 Sep 2026 16:01:31 +0200
Subject: [PATCH] gsupplicant: Enable optional PMF via global Pmf property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260919-pmf-fix-v1-1-a84bab14eb34@outlook.fr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS0NL3YLcNN20zArdFMOUFFMgSko0SlECqi4oSgUKg02Kjq2tBQAIqv+
 6WQAAAA==
X-Change-ID: 20260919-pmf-fix-d1dd5dd5ba2d
To: connman@lists.linux.dev
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789826491; l=3866;
 i=ilyas.tasli@outlook.fr; s=20260919; h=from:subject:message-id;
 bh=EgLdVURvHPPQtsiaA4LiJhJ/WdC3Px5qicPECTierkA=;
 b=IwIc1m50QcKP+bIS6V0qarYsV8wVUJqZsAOICi+Vo7BRk4+bLR7Fpo+eStfNavFFA7OVPovGc
 axyKh8jPiFUBkoKNogJWgVH2npAdHRkYIsep8RRNwxEh3CMcTGJiQ4D
X-Developer-Key: i=ilyas.tasli@outlook.fr; a=ed25519;
 pk=fZdGZtPpfn0Iv4oEHCu8FTesIPeAvMU/PRD3RrLl4mE=
X-Endpoint-Received: by B4 Relay for ilyas.tasli@outlook.fr/20260919 with auth_id=1039
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 5e73b55e ("gsupplicant: Set MFP optional and key_mgmt for PSK")
sets ieee80211w=1 on every PSK network. When ieee80211w is set
explicitly, wpa_supplicant uses it as is and skips its check for BIP
support in the driver. That check only runs when PMF comes from the
global pmf setting.

Drivers without any BIP cipher, e.g. iwlwifi/iwldvm (Centrino
Wireless-N 2230, Advanced-N 6205/6235), therefore negotiate PMF with
PMF-capable APs and then fail to install the IGTK:

  nl80211: kernel reports: key setting validation failed
  wlan0: WPA: Failed to configure IGTK to the driver
  wlan0: RSN: Failed to configure IGTK

The station then deauthenticates locally right after the 4-way
handshake, so it can no longer connect to WPA2 networks it used to
connect to before 1.45.

Set the per-interface global Pmf property to "1" instead and stop
adding ieee80211w to PSK networks. MFPC is still advertised on
hardware that supports PMF, as intended by 5e73b55e. wpa_supplicant
disables PMF itself when the driver lacks BIP. NetworkManager uses
the same approach (NetworkManager commit a9ab50ef, "supplicant: set
optional PMF using global supplicant property").

---
Tested with connman 1.45 and wpa_supplicant 2.11 on an Intel Centrino
Wireless-N 2230 (iwldvm, no BIP cipher advertised) against a WPA2-PSK
AP advertising MFPC: without this patch the connection fails with
"Failed to configure IGTK", with it the station connects and gets a
DHCP lease.
---
 gsupplicant/supplicant.c | 26 ++++++++++++++++----------
 1 file changed, 16 insertions(+), 10 deletions(-)

diff --git a/gsupplicant/supplicant.c b/gsupplicant/supplicant.c
index 5e289953..8e569aed 100644
--- a/gsupplicant/supplicant.c
+++ b/gsupplicant/supplicant.c
@@ -2538,6 +2538,13 @@ static GSupplicantInterface *interface_alloc(const char *path)
 	return interface;
 }
 
+static void set_pmf(DBusMessageIter *iter, void *user_data)
+{
+	const char *pmf = user_data;
+
+	dbus_message_iter_append_basic(iter, DBUS_TYPE_STRING, &pmf);
+}
+
 static void interface_added(DBusMessageIter *iter, void *user_data)
 {
 	GSupplicantInterface *interface;
@@ -2561,6 +2568,15 @@ static void interface_added(DBusMessageIter *iter, void *user_data)
 	if (!interface)
 		return;
 
+	/*
+	 * Enable optional PMF through the per-interface global setting
+	 * instead of per-network ieee80211w=1, so that wpa_supplicant
+	 * disables it when the driver does not support any BIP cipher.
+	 */
+	supplicant_dbus_property_set(path, SUPPLICANT_INTERFACE ".Interface",
+				"Pmf", DBUS_TYPE_STRING_AS_STRING,
+				set_pmf, NULL, "1", NULL);
+
 	if (!properties_appended) {
 		supplicant_dbus_property_get_all(path,
 						SUPPLICANT_INTERFACE ".Interface",
@@ -4930,16 +4946,8 @@ static void add_network_security_proto(DBusMessageIter *dict,
 	g_free(proto);
 }
 
-static void add_network_ieee80211w(DBusMessageIter *dict, GSupplicantSSID *ssid,
-				   GSupplicantMfpOptions ieee80211w)
-{
-	supplicant_dbus_dict_append_basic(dict, "ieee80211w", DBUS_TYPE_UINT32,
-					  &ieee80211w);
-}
-
 static void add_network_security(DBusMessageIter *dict, GSupplicantSSID *ssid)
 {
-	GSupplicantMfpOptions ieee80211w;
 	char *key_mgmt;
 
 	switch (ssid->security) {
@@ -4956,8 +4964,6 @@ static void add_network_security(DBusMessageIter *dict, GSupplicantSSID *ssid)
 		break;
 	case G_SUPPLICANT_SECURITY_PSK:
 		key_mgmt = "SAE WPA-PSK WPA-PSK-SHA256";
-		ieee80211w = G_SUPPLICANT_MFP_OPTIONAL;
-		add_network_ieee80211w(dict, ssid, ieee80211w);
 		add_network_security_psk(dict, ssid);
 		add_network_security_ciphers(dict, ssid);
 		add_network_security_proto(dict, ssid);

---
base-commit: 9e46e4a021cd8566b942d1a72b41b14a0a58f506
change-id: 20260919-pmf-fix-d1dd5dd5ba2d

Best regards,
-- 
Ilyas <ilyas.tasli@outlook.fr>

