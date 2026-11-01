From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sun, 01 Nov 2026 10:06:23 -0600
Subject: [PATCH ath-next] wifi: ath11k: look for firmware-N.bin without the
 user-space fallback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b123-fw-api-n-direct-v1-1-a9b734520abc@gmail.com>
X-B4-Tracking: v=1; b=H4sIAH5j52oC/yWMwQrCMBAFf6W8swvZBBX9FfGQpBu7HmJJohZK/
 92ox2GYWVGlqFSchxVFXlr1kTvwbkCcfL4J6dgZ1tgDs2EKbB2lN/lZKdOoRWKjozuZkPZJYnD
 o6Vwk6fLbXuDbRFmWhuvf1Ge49+h7xbZ9APsX/sCCAAAA
X-Change-ID: 20261101-b123-fw-api-n-direct-7390bf5fecb3
To: Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793549182; l=2493;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=7FihErGI/rxuO2qBCwtRnH7nsLSwQjP+NG+2mzhjaCw=;
 b=h5I/GzmP40OJbuvR6vdmnMCQvlkWlbMBtyvvZuVKywePUAm6injCk7McFvQia3eyFTa035Mz2
 +DeBUl+boJqDIyAJvZC0EQ9KE88czoNVyp3pgM0+Oi68FG+UZlGNV89
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_fw_pre_init() asks for firmware-2.bin through
ath11k_core_firmware_request(), that is firmware_request_nowarn(), and
falls back to API 1 when the file is not there. The file is optional,
and many installations have none: on an Arista C-360 the QCN9074 runs
from amss.bin alone. With CONFIG_FW_LOADER_USER_HELPER_FALLBACK, which
OpenWrt sets, firmware_request_nowarn() still hands a missing file to
the user-space loader, so every probe of such a device waits on a
uevent and its answer, and the loader logs the miss; when the device
goes away before the answer, as when it is unbound right after probing,
the loader then fails to write its answer:

  procd: Failed to write to .../firmware/ath11k!QCN9074!hw1.0!firmware-2.bin/loading: Bad file descriptor

Request it with request_firmware_direct() instead, which looks on the
filesystem only, as ath11k already does for the optional calibration
file in ath11k_qmi_load_bdf_qmi().

Tested-on: QCN9074 hw1.0 PCI WLAN.HK.2.5.r4-00683-QCAHKSWPL_SILICONZ-1

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Seen on an Arista C-360 with OpenWrt: its QCN9074 has no firmware-2.bin,
and its scan radio is unbound right after probing.
---
 drivers/net/wireless/ath/ath11k/fw.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/fw.c b/drivers/net/wireless/ath/ath11k/fw.c
index ef1b4c81843a3..3628e33e57f6e 100644
--- a/drivers/net/wireless/ath/ath11k/fw.c
+++ b/drivers/net/wireless/ath/ath11k/fw.c
@@ -16,10 +16,14 @@ static int ath11k_fw_request_firmware_api_n(struct ath11k_base *ab,
 	struct ath11k_fw_ie *hdr;
 	const u8 *data;
 	__le32 *timestamp;
-
-	ab->fw.fw = ath11k_core_firmware_request(ab, name);
-	if (IS_ERR(ab->fw.fw)) {
-		ret = PTR_ERR(ab->fw.fw);
+	char path[100];
+
+	/* The file is optional: look for it on the filesystem only, so a
+	 * missing one does not go through the user-space fallback loader.
+	 */
+	ath11k_core_create_firmware_path(ab, name, path, sizeof(path));
+	ret = request_firmware_direct(&ab->fw.fw, path, ab->dev);
+	if (ret) {
 		ath11k_dbg(ab, ATH11K_DBG_BOOT, "failed to load %s: %d\n", name, ret);
 		ab->fw.fw = NULL;
 		return ret;

---
base-commit: a3ddbb45768717b5c9f923489387cf55c838d1ad
change-id: 20261101-b123-fw-api-n-direct-7390bf5fecb3

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

