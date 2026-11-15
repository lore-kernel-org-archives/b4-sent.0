From: Alexis Calin <alexiscalin@protonmail.com>
Date: Sun, 15 Nov 2026 14:04:24 +0100
Subject: [PATCH] wpa_supplicant: Initialize is_6ghz_enabled when adding an
 interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-init-is-6ghz-enabled-v1-1-fe1baa0bf9cf@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MOwqAMBBF0a3I1A6YqEHcilj4eSYDEiUREcW9G
 yxPce9DEUEQqc0eCjglyuYTVJ7R5AZvwTInky60UUrVLF4OlsjGupvhh3HFzEVZoTYNzKInSuk
 esMj1b7v+fT8y8oWBZgAAAA==
X-Change-ID: 20261115-init-is-6ghz-enabled-034e568e6f2c
To: hostap@lists.infradead.org
Cc: Alexis Calin <alexiscalin@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794747868; l=3357;
 i=alexiscalin@protonmail.com; s=20261114; h=from:subject:message-id;
 bh=XS45mzErUril3n0/bEQUEMI5b/tthZeqNMRNBjbLRkY=;
 b=Qj/jeHy0WKxW6zRJn1KnPoraoHLPVDIcHLzvnkYPsI22ibmu/AFauatURBJE4c1jrAad9y9dj
 aTM7tXGQVh7Ac8mFg2R/A16/iXJpJHhaxafSbp5bz32V3dR3VRJxOfq
X-Developer-Key: i=alexiscalin@protonmail.com; a=ed25519;
 pk=oNYBG1X8+3bGmJMn0tnt+BbJC1vI7dgqomx4pGPM+4c=
X-Endpoint-Received: by B4 Relay for alexiscalin@protonmail.com/20261114 with auth_id=1528
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

is_6ghz_enabled is only updated in wpa_supplicant_update_channel_list(),
so it is false until the first channel list change after an interface
is added, even if 6 GHz channels were enabled from the start. That first
change is then reported as "6 GHz was enabled": crossed_6ghz_dom is set,
wpa_supplicant_fast_associate() rejects the scan results and a new scan
is done before connecting, even though the previous scan covered 6 GHz.

This affects connections where the interface was added shortly before,
e.g., with NetworkManager, which re-adds the interface after resume and
takes it down and up to change the MAC address before connecting.
ath11k reports a channel list change when the station interface is
added, so the extra scan happens on every such connection. With WCN6855,
where a scan takes about 5 seconds, this delays every reconnection after
resume by that much.

Initialize is_6ghz_enabled along with support_6ghz when the hardware
features are read, so that only an actual change from no enabled 6 GHz
channels to enabled ones is treated as crossing into a 6 GHz domain.

Fixes: 42add3c27ba0 ("Scan 6 GHz channels after change to 6 GHz-allowed regdom")
Assisted-by: LLM
Signed-off-by: Alexis Calin <alexiscalin@protonmail.com>
---
Tested on a ThinkPad P14s Gen 5 AMD with a Qualcomm WCN6855 (ath11k,
Linux 7.2.13) and NetworkManager 1.56.1, using Fedora's wpa_supplicant
2.11 rebuilt with and without this change. Over 3 suspend/resume cycles
each, without the change wpa_supplicant logs "6 GHz was enabled" and
"Fast associate: Crossed 6 GHz domain" after the interface is re-added,
and scans again for 5 s before authenticating; Wi-Fi is back 12.6-12.7 s
after the wake-up. With the change, it authenticates 0.09 s after
NetworkManager starts the connection, using the scan done right before,
and Wi-Fi is back after 6.6-7.6 s.

The issue also shows with mac80211_hwsim and a plain wpa_supplicant
(-D nl80211, no network configured): with the regulatory domain set to
FR before starting wpa_supplicant, "iw reg set US" makes it log "Channel
list changed: 6 GHz was enabled" although 6 GHz was enabled before. With
this change it does not, and starting with "00" and then setting "US"
still logs it.

The hwsim modules scan, he, sta_dynamic, dbus, ap_open, ap_psk and
wpas_ctrl (in KVM, on main) give the same results with and without
this change. In both cases, dbus_roam fails and
sta_dynamic_random_mac_addr_two_aps fails intermittently (4/10 and 5/10
runs). None of the hwsim tests covers crossed_6ghz_dom directly.
---
 wpa_supplicant/wpa_supplicant.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/wpa_supplicant/wpa_supplicant.c b/wpa_supplicant/wpa_supplicant.c
index 74fad8678..f20f37b95 100644
--- a/wpa_supplicant/wpa_supplicant.c
+++ b/wpa_supplicant/wpa_supplicant.c
@@ -8963,6 +8963,7 @@ static int wpa_supplicant_init_iface(struct wpa_supplicant *wpa_s,
 				wpa_s->hw_capab |= BIT(CAPAB_HT);
 		}
 		wpa_s->support_6ghz = wpas_is_6ghz_supported(wpa_s, false);
+		wpa_s->is_6ghz_enabled = wpas_is_6ghz_supported(wpa_s, true);
 	}
 
 	capa_res = wpa_drv_get_capa(wpa_s, &capa);

---
base-commit: 32f3d323a41518fbe8a9930a34abac3a1d789087
change-id: 20261115-init-is-6ghz-enabled-034e568e6f2c

Best regards,
-- 
Alexis Calin <alexiscalin@protonmail.com>

