From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:19:22 +0000
Subject: [PATCH v3 2/2] usb: typec: fusb302: Toggle with the default Rp
 current
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-tcpm-attach-reboot-v3-2-1c97dfa5024a@gmail.com>
References: <20261126-tcpm-attach-reboot-v3-0-1c97dfa5024a@gmail.com>
In-Reply-To: <20261126-tcpm-attach-reboot-v3-0-1c97dfa5024a@gmail.com>
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795684760; l=1959;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=FMswpD7V3DPAN3VSP6u/NBb3U0lujecrXjPnwM/C3ww=;
 b=IkegyDSSVxo1YrjdpWsl/T4MeCRH2GmVL0WbsdLAscAQUIppgLhut10FHxllTrHU0NTalXkjo
 fNHD/lY9irXD+lYlJE95huL9zqmw1bKc3kjbW/Jcqtw9+2tM0ycNw9g
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FUSB302 does not detect some sinks while toggling with Rp 3.0A.
Toggle with the default current and set the requested one on attach.

Fixes: c034a43e72dd ("staging: typec: Fairchild FUSB302 Type-c chip driver")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/typec/tcpm/fusb302.c | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/typec/tcpm/fusb302.c b/drivers/usb/typec/tcpm/fusb302.c
index 83bd287dadc7..64d02cc0ecae 100644
--- a/drivers/usb/typec/tcpm/fusb302.c
+++ b/drivers/usb/typec/tcpm/fusb302.c
@@ -97,6 +97,7 @@ struct fusb302_chip {
 	/* chip status */
 	enum toggling_mode toggling_mode;
 	enum src_current_status src_current_status;
+	enum src_current_status toggling_src_current;
 	bool intr_togdone;
 	bool intr_bc_lvl;
 	bool intr_comp_chng;
@@ -942,10 +943,11 @@ static int tcpm_start_toggling(struct tcpc_dev *dev,
 	}
 
 	mutex_lock(&chip->lock);
-	ret = fusb302_set_src_current(chip, cc_src_current[cc]);
+	chip->toggling_src_current = cc_src_current[cc];
+	ret = fusb302_set_src_current(chip, SRC_CURRENT_DEFAULT);
 	if (ret < 0) {
 		fusb302_log(chip, "unable to set src current %s, ret=%d",
-			    typec_cc_status_name[cc], ret);
+			    typec_cc_status_name[TYPEC_CC_RP_DEF], ret);
 		goto done;
 	}
 	ret = fusb302_set_toggling(chip, mode);
@@ -1357,6 +1359,12 @@ static int fusb302_handle_togdone_src(struct fusb302_chip *chip,
 			    typec_cc_status_name[cc2]);
 		return fusb302_set_toggling(chip, toggling_mode);
 	}
+	ret = fusb302_set_src_current(chip, chip->toggling_src_current);
+	if (ret < 0) {
+		fusb302_log(chip, "cannot set src current, ret=%d", ret);
+		return ret;
+	}
+	rd_mda = rd_mda_value[chip->src_current_status];
 	/* set polarity and pull_up, pull_down */
 	ret = fusb302_set_cc_polarity_and_pull(chip, cc_polarity, true, false);
 	if (ret < 0) {

-- 
2.55.0

