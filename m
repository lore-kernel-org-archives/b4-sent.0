From: Thomas Roos <thomas@exein.io>
Date: Tue, 24 Nov 2026 09:11:12 +0100
Subject: [PATCH] scsi: ufs: spacemit: k3: change to FASTAUTO before the
 FAST power mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-fastauto-v1-1-32ec8da5af04@exein.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2O227DIBBEf8XiuVtxsTG2qir/UeUBwzqliY3DQ
 lQpyr+XxH0c6cycuTPCFJDY2NxZwlugENcaxFvD3LddTwjB18wkl1oIqWC2lG3JERTXXnIv+m7
 grOJbwjn8vqa+jnumMv2gy8/+P5HwWqoj7xhbkMi+HGPzsSuEBm7grKDMBFS2LaYMNwMcUE2y0
 0MvvW8PZ0wrXt5jOn0+pydLCC4uS8hjo7U02PvW6VpwxgszC9V2qGz9K4WRg7XYY8uOj8cfoN2
 MXwEBAAA=
X-Change-ID: 20261123-fastauto-306d20d17590
To: Yixun Lan <dlan@kernel.org>
Cc: linux-kernel@vger.kernel.org, "Martin K. Petersen" <mkp@kernel.org>, 
 Avri Altman <avri.altman@sandisk.com>, 
 Aurelien Jarno <aurelien@aurel32.net>, linux-riscv@lists.infradead.org, 
 spacemit@lists.linux.dev, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Bart Van Assche <bvanassche@acm.org>, 
 linux-scsi@vger.kernel.org, Thomas Roos <thomas@exein.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795507873; l=7608;
 i=thomas@exein.io; s=20261123; h=from:subject:message-id;
 bh=RymV5zMbzsG2XTIPvNgJCqbPkkuUhbtDXJ6LBGWwEoY=;
 b=R9TDgIgztndqSoyDV01RA//UNz8TnzB9NUqSP2DihhF57O6C9DSwIzZRo3gCsSbQZGbEPmfjR
 f4LjHNzWK+gAnP9AKwLAoFe/RRNiSUogSJeq0xIYBaAD5pcwmTa1fQo
X-Developer-Key: i=thomas@exein.io; a=ed25519;
 pk=/1K7FRX9hsKzsRpNzb4iTkD9xST9v3ePGJm6wu2ntMw=
X-Endpoint-Received: by B4 Relay for thomas@exein.io/20261123 with auth_id=1621
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SpacemiT vendor kernel and U-Boot never change the link straight to
FAST: they change to FASTAUTO at the target gear/rate first, wait
100 ms, and only then to FAST. A direct FAST change kills the link at
the M-PHY PLL rate change: on the K3 CoM260 IFX (YMTC YMUS8B5TH1A1C1)
every mode except HS-G1 rate A fails with DL errors 0x80000002 /
0x80000001 / 0x80002000 and PA_ERR 0x80000010, and the disk is lost.

Do the FASTAUTO step in the PRE_CHANGE hook; the core then sends the
FAST request. With this the link runs at HS-G3 rate B on two lanes.

Skip the step only when the link already runs in FAST with the
requested parameters, judged by PA_PWRMODE and not by hba->pwr_info
alone. After a LINERESET, ufshcd_err_handler() restores the power mode
with ufshcd_config_pwr_mode(hba, &hba->pwr_info, UFSHCD_PMC_POLICY_FORCE):
the requested parameters equal hba->pwr_info, but the link has fallen
back to a slow mode, and the forced FAST request would kill it again.

The step also writes ANA_HSGEAR_CTRL_ATTR = 0x25 and waits for the PLL
lock, as ufs_spacemit_apply_dev_quirks() does at probe. Every POST_CHANGE
clears the attribute, so without this a LINERESET recovery would run the
FASTAUTO and FAST changes with a different analog setting than probe.

Assisted-by: claude-opus-5-5
Signed-off-by: Thomas Roos <thomas@exein.io>
---
This applies on top of v8 of "scsi: ufs: spacemit: k3: Add UFS Host
Controller driver":
https://lore.kernel.org/r/20261116-08-k3-ufs-support-v8-2-e3b256972dd4@kernel.org

Yixun, feel free to fold it into the next version of the series.

Tested on a K3 CoM260 IFX (YMTC YMUS8B5TH1A1C1) on 7.3.4 with the
equivalent v7-based driver: without the change only HS-G1 rate A works;
with it the link runs at HS-G3 rate B x2 and the rootfs on UFS is
stable. Builds without warnings at W=1 on top of v8.

The restore path was exercised with this patch: a test-only debugfs
hook drops the link to PWM-G1 SLOWAUTO behind the core (raw reads fall
from ~900 MB/s to 1 MB/s), then a PA generic error is injected through
the ufshcd debugfs saved_uic_err. In 6 of 6 runs the restore went
through FASTAUTO back to G3B FAST, with reads at 850-980 MB/s again and
a matching write/read-back. That setup keeps the PHY on rate B, so it
does not reproduce a LINERESET that also resets the PLL rate.

The FASTAUTO step open-codes the attribute writes of the core's
ufshcd_dme_change_power_mode(). A core helper that takes an explicit
PA_PWRMODE value and leaves hba->pwr_info alone would avoid that; I kept
it in the driver for now.
---
 drivers/ufs/host/ufs-spacemit.c | 96 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 96 insertions(+)

diff --git a/drivers/ufs/host/ufs-spacemit.c b/drivers/ufs/host/ufs-spacemit.c
index eb2ad50..04380a0 100644
--- a/drivers/ufs/host/ufs-spacemit.c
+++ b/drivers/ufs/host/ufs-spacemit.c
@@ -343,6 +343,87 @@ static int ufs_spacemit_negotiate_pwr_mode(struct ufs_hba *hba,
 	return ret;
 }
 
+/*
+ * As in the vendor kernel and U-Boot: change to FASTAUTO at the target
+ * gear/rate first and only then (from the core) to FAST. A direct FAST
+ * change kills the link after the M-PHY PLL rate change, so only HS-G1A
+ * would work.
+ */
+static int ufs_spacemit_fastauto_step(struct ufs_hba *hba,
+				      struct ufs_pa_layer_attr *p)
+{
+	int ret;
+
+	/*
+	 * Restore the value and PLL lock wait of ufs_spacemit_apply_dev_quirks()
+	 * at probe: every POST_CHANGE resets it, which matters for a LINERESET
+	 * recovery.
+	 */
+	ufshcd_dme_set(hba, UIC_ARG_MIB(ANA_HSGEAR_CTRL_ATTR), 0x25);
+	ret = ufs_spacemit_wait_mphy_pll_lock(hba);
+	if (ret)
+		return ret;
+
+	ufshcd_dme_set(hba, UIC_ARG_MIB(PA_RXGEAR), p->gear_rx);
+	ufshcd_dme_set(hba, UIC_ARG_MIB(PA_ACTIVERXDATALANES), p->lane_rx);
+	ufshcd_dme_set(hba, UIC_ARG_MIB(PA_RXTERMINATION), 1);
+	ufshcd_dme_set(hba, UIC_ARG_MIB(PA_TXGEAR), p->gear_tx);
+	ufshcd_dme_set(hba, UIC_ARG_MIB(PA_ACTIVETXDATALANES), p->lane_tx);
+	ufshcd_dme_set(hba, UIC_ARG_MIB(PA_TXTERMINATION), 1);
+	ufshcd_dme_set(hba, UIC_ARG_MIB(PA_HSSERIES), p->hs_rate);
+	/* as in ufshcd_dme_change_power_mode() */
+	if (!(hba->quirks & UFSHCD_QUIRK_SKIP_DEF_UNIPRO_TIMEOUT_SETTING)) {
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_PWRMODEUSERDATA0),
+			       DL_FC0ProtectionTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_PWRMODEUSERDATA1),
+			       DL_TC0ReplayTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_PWRMODEUSERDATA2),
+			       DL_AFC0ReqTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_PWRMODEUSERDATA3),
+			       DL_FC1ProtectionTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_PWRMODEUSERDATA4),
+			       DL_TC1ReplayTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(PA_PWRMODEUSERDATA5),
+			       DL_AFC1ReqTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(DME_LocalFC0ProtectionTimeOutVal),
+			       DL_FC0ProtectionTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(DME_LocalTC0ReplayTimeOutVal),
+			       DL_TC0ReplayTimeOutVal_Default);
+		ufshcd_dme_set(hba, UIC_ARG_MIB(DME_LocalAFC0ReqTimeOutVal),
+			       DL_AFC0ReqTimeOutVal_Default);
+	}
+
+	ret = ufshcd_uic_change_pwr_mode(hba, FASTAUTO_MODE << 4 | FASTAUTO_MODE);
+	if (ret)
+		return ret;
+	msleep(100);
+
+	return ufs_spacemit_wait_mphy_pll_lock(hba);
+}
+
+/*
+ * True if the link already runs in FAST with the gear, lanes and rate of
+ * @p, so no FASTAUTO step is needed. Read PA_PWRMODE rather than trust
+ * hba->pwr_info alone: after a LINERESET the error handler restores the
+ * mode with UFSHCD_PMC_POLICY_FORCE and parameters equal to hba->pwr_info
+ * while the link has fallen back to a slow mode, and the forced FAST
+ * request from there kills the link.
+ */
+static bool ufs_spacemit_link_in_fast(struct ufs_hba *hba,
+				      struct ufs_pa_layer_attr *p)
+{
+	u32 mode;
+
+	if (memcmp(p, &hba->pwr_info, sizeof(*p)))
+		return false;
+
+	if (ufshcd_dme_get(hba, UIC_ARG_MIB(PA_PWRMODE), &mode))
+		return false;
+
+	return ((mode >> PWRMODE_RX_OFFSET) & PWRMODE_MASK) == FAST_MODE &&
+	       (mode & PWRMODE_MASK) == FAST_MODE;
+}
+
 static int ufs_spacemit_pwr_change_notify(struct ufs_hba *hba,
 					  enum ufs_notify_change_status status,
 					  struct ufs_pa_layer_attr *dev_req_params)
@@ -356,6 +437,21 @@ static int ufs_spacemit_pwr_change_notify(struct ufs_hba *hba,
 
 	switch (status) {
 	case PRE_CHANGE:
+		/* the core sends the FAST request after this hook */
+		if (dev_req_params->pwr_rx == FAST_MODE &&
+		    dev_req_params->pwr_tx == FAST_MODE &&
+		    !ufs_spacemit_link_in_fast(hba, dev_req_params)) {
+			/*
+			 * The core ignores the result. If the FASTAUTO PMC
+			 * failed outside a PM operation, the link is marked
+			 * broken and the FAST request is not sent; if only the
+			 * PLL lock wait timed out, the link already runs at
+			 * the target rate.
+			 */
+			ret = ufs_spacemit_fastauto_step(hba, dev_req_params);
+			if (ret)
+				dev_warn(hba->dev, "FASTAUTO step failed: %d\n", ret);
+		}
 		break;
 	case POST_CHANGE:
 		ret = ufs_spacemit_wait_mphy_pll_lock(hba);

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261123-fastauto-306d20d17590
prerequisite-message-id: <20261116-08-k3-ufs-support-v8-0-e3b256972dd4@kernel.org>
prerequisite-patch-id: 70385741c42f21fbc79b3ef967e48cb8214e5cd0
prerequisite-patch-id: 5198841accdd660ed1597e92dcdef85a6accc8cd

Best regards,
--  
Thomas Roos <thomas@exein.io>

