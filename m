From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Wed, 04 Nov 2026 09:37:44 -0600
Subject: [PATCH] ACS: Fall back to the BSS-based study when the survey
 finds no channel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b138-acs-bss-fallback-v1-1-f9bd40d23b0e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEdR62oC/yXMTQ6CQAxA4auQrm1CUX70KoTFdOxolSCZojGZc
 HdHWH6L9xKYRBWDS5EgykdNX1MGHQrwdzfdBPWaDVVZNUTlCZmOHTpvyGYY3Diy80/smrZuzyS
 hDgy5naME/W7ffthtb36IX/4zWNcf2BQZNXkAAAA=
X-Change-ID: 20261104-b138-acs-bss-fallback-8675791ef5fb
To: hostap@lists.infradead.org
Cc: Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793806663; l=3450;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=9nKpJl3d01I1cU/zyRlSYmoizs1dp9pXV/6XN8qVHnk=;
 b=rGgSAemPzD/16BCP9j6eUFKUzLGisZn8J7sQ1+SjDCWjE6iQdOtLMAt4ZLJRuZTPewWTp9YOy
 xD8spkSZcnYAPswvTSUqBsw/t0yLm5ljKuCo1aeXwD2oewhhs/Nmc/3
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

acs_study() falls back to the BSS-based study only when no channel at
all has sufficient survey data. When some do, but none that can be
selected, acs_find_ideal_chan() finds no channel and ACS fails, and
the interface is not started.

That happens with a driver that reports a noise floor only for some
channels. ath11k on QCN9074 does so on 6 GHz: a channel the radio
operated on keeps its survey entry with the noise floor, while the
channels the ACS scan visits get entries without one. With
chanlist=5 37 69 101 133 165 197 at 160 MHz, after the radio ran on
channel 21, the one sufficient channel cannot be a primary channel,
and every attempt fails:

  ACS: Failed to compute ideal channel
  ACS: Failed to start
  Interface initialization failed

Run the BSS-based study in that case too, as when the survey data is
insufficient everywhere. The BSS-based study marks the channels it
rates for that run only, so clear the mark at ACS cleanup; it stayed
set before, and a later ACS run took those channels as usable whatever
their survey said.

Tested on two Arista APs with QCN9074 6 GHz radios: on the first, 2 of
2 attempts failed as above; on the second, the same sequence failed
before, and with this change ACS completed at 160 MHz on two runs in a
row, the second after "Survey based ACS found no channel - trying
BSS-based ACS".

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen on OpenWrt, where a 6 GHz radio at 160 MHz then stayed down until
its next restart, a boot included.
---
 src/ap/acs.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/src/ap/acs.c b/src/ap/acs.c
index 1966d8e..a4e25ce 100644
--- a/src/ap/acs.c
+++ b/src/ap/acs.c
@@ -342,6 +342,7 @@ static void acs_cleanup_mode(struct hostapd_hw_modes *mode)
 		chan->flag |= HOSTAPD_CHAN_SURVEY_LIST_INITIALIZED;
 		chan->min_nf = 0;
 		chan->punct_bitmap = 0;
+		chan->interference_bss_based = false;
 	}
 }
 
@@ -1300,6 +1301,21 @@ static int acs_study_options(struct hostapd_iface *iface)
 }
 
 
+static bool acs_studied_bss_based(struct hostapd_iface *iface)
+{
+	int i;
+
+	if (!iface->current_mode)
+		return false;
+
+	for (i = 0; i < iface->current_mode->num_channels; i++)
+		if (iface->current_mode->channels[i].interference_bss_based)
+			return true;
+
+	return false;
+}
+
+
 static void acs_study(struct hostapd_iface *iface)
 {
 	struct hostapd_channel_data *ideal_chan;
@@ -1312,6 +1328,16 @@ static void acs_study(struct hostapd_iface *iface)
 	}
 
 	ideal_chan = acs_find_ideal_chan(iface);
+	if (!ideal_chan && !acs_studied_bss_based(iface)) {
+		/* The survey data was sufficient for some channels, but none
+		 * that could be selected, e.g., when the driver reports no
+		 * noise floor for the others. Use the BSS-based study, as
+		 * when no channel has sufficient survey data. */
+		wpa_printf(MSG_INFO,
+			   "ACS: Survey based ACS found no channel - trying BSS-based ACS");
+		if (acs_study_bss_based(iface) == 0)
+			ideal_chan = acs_find_ideal_chan(iface);
+	}
 	if (!ideal_chan) {
 		wpa_printf(MSG_ERROR, "ACS: Failed to compute ideal channel");
 		err = -1;

---
base-commit: 412ff0d7f4d2b346df63be52c4201ee7ab0dc804
change-id: 20261104-b138-acs-bss-fallback-8675791ef5fb

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

