From: =?utf-8?q?Burak_G=C3=B6nc=C3=BC?= <burakgon12@gmail.com>
Date: Thu, 15 Oct 2026 01:26:40 +0300
Subject: [PATCH v2 1/2] drm/i915/tc: serialize the TCSS power request
 mailbox
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261015-ptl-port-b-tcss-v2-1-e00ce882402d@gmail.com>
References: <20261015-ptl-port-b-tcss-v2-0-e00ce882402d@gmail.com>
In-Reply-To: <20261015-ptl-port-b-tcss-v2-0-e00ce882402d@gmail.com>
To: intel-gfx@lists.freedesktop.org, intel-xe@lists.freedesktop.org
Cc: Jani Nikula <jani.nikula@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, Imre Deak <imre.deak@intel.com>, 
 Mika Kahola <mika.kahola@intel.com>, 
 =?utf-8?q?Burak_G=C3=B6nc=C3=BC?= <burakgon12@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016806; l=3572;
 i=burakgon12@gmail.com; s=20261006; h=from:subject:message-id;
 bh=HDrQGwPbeM4EaZDDv9YBRrwkXDsf8pSwnEvQsuP639Q=;
 b=hZkiOKriVZuQFgr7cGZb+Id9ihqM1SdGS/228Hl3sc7uxEyT9ijWDg2MkscroU/ZTHSlgUFfh
 g8IQ2rQ+8qxBRKBsmnRrHGEhUODmp9j7Hv9/84t6mGvQcMZfiWXrwHG
X-Developer-Key: i=burakgon12@gmail.com; a=ed25519;
 pk=qcexQajnoYGkNqFOy3eFqTzvqTOR/P++ksapi6qUbvw=
X-Endpoint-Received: by B4 Relay for burakgon12@gmail.com/20261006 with auth_id=1126
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xelpdp_tc_power_request_wa() (Wa_14020908590) drives the TCSS mailbox,
which is shared by all ports: it waits for the mailbox to be idle,
writes TCSS_DISP_MAILBOX_IN_DATA and TCSS_DISP_MAILBOX_IN_CMD, and waits
for the command to finish. Its callers hold only their own TC port's
lock, so two TC ports enabling or disabling TCSS power at the same time
can interleave these steps and run one port's command with the other
port's data.

Serialize the sequence with a display-wide mutex. The next patch adds a
caller outside of the TC port code.

Assisted-by: LLM
Signed-off-by: Burak Göncü <burakgon12@gmail.com>
---
 drivers/gpu/drm/i915/display/intel_display_core.h   |  5 +++++
 drivers/gpu/drm/i915/display/intel_display_driver.c |  1 +
 drivers/gpu/drm/i915/display/intel_tc.c             | 12 ++++++++----
 3 files changed, 14 insertions(+), 4 deletions(-)

diff --git a/drivers/gpu/drm/i915/display/intel_display_core.h b/drivers/gpu/drm/i915/display/intel_display_core.h
index c80b4a2f7..dc1df97d8 100644
--- a/drivers/gpu/drm/i915/display/intel_display_core.h
+++ b/drivers/gpu/drm/i915/display/intel_display_core.h
@@ -623,6 +623,11 @@ struct intel_display {
 		u32 bxt_phy_grc;
 	} state;
 
+	struct {
+		/* serializes the TCSS mailbox of Wa_14020908590 */
+		struct mutex mailbox_lock;
+	} tc;
+
 	struct {
 		unsigned int hpll_freq;
 		unsigned int czclk_freq;
diff --git a/drivers/gpu/drm/i915/display/intel_display_driver.c b/drivers/gpu/drm/i915/display/intel_display_driver.c
index 70d112fd4..e1b445305 100644
--- a/drivers/gpu/drm/i915/display/intel_display_driver.c
+++ b/drivers/gpu/drm/i915/display/intel_display_driver.c
@@ -187,6 +187,7 @@ void intel_display_driver_early_probe(struct intel_display *display)
 	mutex_init(&display->wm.wm_mutex);
 	mutex_init(&display->pps.mutex);
 	mutex_init(&display->hdcp.hdcp_mutex);
+	mutex_init(&display->tc.mailbox_lock);
 
 	intel_display_irq_init(display);
 	intel_dkl_phy_init(display);
diff --git a/drivers/gpu/drm/i915/display/intel_tc.c b/drivers/gpu/drm/i915/display/intel_tc.c
index f2d86b29c..9285e70ef 100644
--- a/drivers/gpu/drm/i915/display/intel_tc.c
+++ b/drivers/gpu/drm/i915/display/intel_tc.c
@@ -1068,12 +1068,15 @@ xelpdp_tc_phy_wait_for_tcss_power(struct intel_tc_port *tc, bool enabled)
  */
 static void xelpdp_tc_power_request_wa(struct intel_display *display, bool enable)
 {
+	/* the mailbox is shared by all ports, keep their commands apart */
+	mutex_lock(&display->tc.mailbox_lock);
+
 	/* check if mailbox is running busy */
 	if (intel_de_wait_for_clear_ms(display, TCSS_DISP_MAILBOX_IN_CMD,
 				       TCSS_DISP_MAILBOX_IN_CMD_RUN_BUSY, 10)) {
 		drm_dbg_kms(display->drm,
 			    "Timeout waiting for TCSS mailbox run/busy bit to clear\n");
-		return;
+		goto out_unlock;
 	}
 
 	intel_de_write(display, TCSS_DISP_MAILBOX_IN_DATA, enable ? 1 : 0);
@@ -1083,11 +1086,12 @@ static void xelpdp_tc_power_request_wa(struct intel_display *display, bool enabl
 
 	/* wait to clear mailbox running busy bit before continuing */
 	if (intel_de_wait_for_clear_ms(display, TCSS_DISP_MAILBOX_IN_CMD,
-				       TCSS_DISP_MAILBOX_IN_CMD_RUN_BUSY, 10)) {
+				       TCSS_DISP_MAILBOX_IN_CMD_RUN_BUSY, 10))
 		drm_dbg_kms(display->drm,
 			    "Timeout after writing data to mailbox. Mailbox run/busy bit did not clear\n");
-		return;
-	}
+
+out_unlock:
+	mutex_unlock(&display->tc.mailbox_lock);
 }
 
 static void __xelpdp_tc_phy_enable_tcss_power(struct intel_tc_port *tc, bool enable)

-- 
2.56.0

