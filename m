From: Jason Lee <jay@ruby.im>
Date: Fri, 30 Oct 2026 20:13:01 -0400
Subject: [PATCH] wifi: ath11k: Warn when loading regdb fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-ath11k-regdb-warn-v1-1-17738169bcc5@ruby.im>
X-B4-Tracking: v=1; b=H4sIAIwy5WoC/yXMTQqEMAxA4atI1hNoHEbUq8gsqo0ahSqpPwPi3
 afq8lu8d0BgFQ5QJgcobxJk8hH0SqDpre8YxUVDatKMzNugXXqiEZU7V+Nu1aP5FK5oyVGeE8R
 uVm7ldz+r7+Ow1gM3yzWC8/wDKqzbJ3UAAAA=
X-Change-ID: 20261030-ath11k-regdb-warn-059d9f1d1881
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jason Lee <jay@ruby.im>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793405586; l=1920;
 i=jay@ruby.im; s=20261030; h=from:subject:message-id;
 bh=JfWZf+GvrJDa+0KJN3EFYz0wha5Nl7sP4WnES3xHdHM=;
 b=Y0+BzrE+FuAYMu7499B6t/YD5DPOiDS+dkw7KR70KC0Ww1aeLrvB3cBd/GJVmdK0b4WTuW42q
 rMdPqzZmLN8D2uwmKbCgu04Jn9XERqikmJaiyuRhpeNnvKshE/EW+sQ
X-Developer-Key: i=jay@ruby.im; a=ed25519;
 pk=nwVVsNgYUApfCPxmvZyTv0afv7bOSDky/hRrOjJKzys=
X-Endpoint-Received: by B4 Relay for jay@ruby.im/20261030 with auth_id=1367
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_qmi_event_load_bdf() loads the regulatory database before the
board data file on hardware that supports it, but ignores the return
value of ath11k_qmi_load_bdf_qmi(ab, true). When the regdb is present
and cannot be loaded, the driver carries on silently and nothing in the
log says why the external regdb.bin is not being used.

regdb.bin is optional, so a missing file (-ENOENT) stays quiet, as it
is today (ath11k_core_fetch_regdb() already reports it at debug level).
Any other error is now reported with a warning. Loading still continues
either way, so behaviour does not change.

Compile tested only.

Closes: https://bugzilla.kernel.org/show_bug.cgi?id=216664
Signed-off-by: Jason Lee <jay@ruby.im>
---
Compile tested only (x86_64 defconfig + ATH11K/ATH11K_PCI=m, W=1, no new
warnings); I don't have ath11k hardware to test on.

An AI assistant helped find this bug report and draft the change.
---
 drivers/net/wireless/ath/ath11k/qmi.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/qmi.c b/drivers/net/wireless/ath/ath11k/qmi.c
index 7dc07339b9..e8096aca96 100644
--- a/drivers/net/wireless/ath/ath11k/qmi.c
+++ b/drivers/net/wireless/ath/ath11k/qmi.c
@@ -2976,8 +2976,12 @@ static int ath11k_qmi_event_load_bdf(struct ath11k_qmi *qmi)
 		return ret;
 	}
 
-	if (ab->hw_params.supports_regdb)
-		ath11k_qmi_load_bdf_qmi(ab, true);
+	if (ab->hw_params.supports_regdb) {
+		/* regdb is optional, so a missing file is not an error */
+		ret = ath11k_qmi_load_bdf_qmi(ab, true);
+		if (ret < 0 && ret != -ENOENT)
+			ath11k_warn(ab, "failed to load regdb file: %d\n", ret);
+	}
 
 	ret = ath11k_qmi_load_bdf_qmi(ab, false);
 	if (ret < 0) {

---
base-commit: a9547379cb381e2a036e3261a6becc17973ac470
change-id: 20261030-ath11k-regdb-warn-059d9f1d1881

Best regards,
--  
Jason Lee <jay@ruby.im>

