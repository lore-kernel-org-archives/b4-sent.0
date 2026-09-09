From: Roland Dreier <rolanddreier@rivian.com>
Date: Wed, 09 Sep 2026 17:58:59 +0000
Subject: [PATCH] firmware: arm_scmi: Fix error path leak in
 scmi_raw_message_send()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-scmi-raw-v1-1-de3fa75d2c6f@rivian.com>
X-B4-Tracking: v=1; b=H4sIAGKeoWoC/yXM3QpAQBCG4VvRHNsahLgVOVhrllF+2vFXcu8Wh
 0+933eBkGMSKIMLHO0sPE8eURiA6fXUkeLWG2KMMyywUGJGVk4fCq1NLDWpxjwBny+OLJ/fVVX
 /lq0ZyKzvHu77AWfXCqhsAAAA
X-Change-ID: 20260909-scmi-raw-0ff3feb5a073
To: Sudeep Holla <sudeep.holla@kernel.org>, 
 Cristian Marussi <cristian.marussi@arm.com>
Cc: arm-scmi@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Sashiko <sashiko-bot@kernel.org>, 
 Roland Dreier <rolanddreier@rivian.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788976750; l=1401;
 i=rolanddreier@rivian.com; s=20260814; h=from:subject:message-id;
 bh=ulhzZqaSwBOt3awtuXWQe6D8VST705i7vhwvE1JyWas=;
 b=JKBsDDq4LGcT0kglXB6DsxiCDeXT92Dxot3q04+qCvF0saYsODSHs0CU+wFYqxRjYsAICdNWr
 ICITTR1FohHBDKI+3eDcOAyowR2GrTj861j+uevgLJs0L0jabq16Qmt
X-Developer-Key: i=rolanddreier@rivian.com; a=ed25519;
 pk=C7SBXsDIlarq7BpINqyDL67XV/AGNqNt09NCCpFcExk=
X-Endpoint-Received: by B4 Relay for rolanddreier@rivian.com/20260814 with auth_id=952
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the is_transport_polling_capable() check fails in scmi_raw_message_send(),
it returns -EINVAL without doing scmi_xfer_raw_put(), which will leak a
struct scmi_xfer.

Reported-by: Sashiko <sashiko-bot@kernel.org>
Link: https://sashiko.dev/#/patchset/20260909-scmi-async-done-race-v2-0-cc5dec25c6be%40rivian.com
Fixes: 07cb8c324b63 ("firmware: arm_scmi: Add polling support to raw mode")
Signed-off-by: Roland Dreier <rolanddreier@rivian.com>
---
Sashiko pointed out this pre-existing bug when reviewing my patchset:
https://sashiko.dev/#/patchset/20260909-scmi-async-done-race-v2-0-cc5dec25c6be%40rivian.com

Fix is trivial so sending it out.
---
 drivers/firmware/arm_scmi/raw_mode.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/firmware/arm_scmi/raw_mode.c b/drivers/firmware/arm_scmi/raw_mode.c
index 1f6e51670208..279fee7c6ce9 100644
--- a/drivers/firmware/arm_scmi/raw_mode.c
+++ b/drivers/firmware/arm_scmi/raw_mode.c
@@ -694,6 +694,7 @@ static int scmi_raw_message_send(struct scmi_raw_mode_info *raw,
 		} else {
 			dev_err(raw->handle->dev,
 				"Failed to send RAW message - Polling NOT supported\n");
+			scmi_xfer_raw_put(raw->handle, xfer);
 			return -EINVAL;
 		}
 	}

---
base-commit: 893e11787f78e43b534e252249ac3fff4d1333f8
change-id: 20260909-scmi-raw-0ff3feb5a073

Best regards,
--  
Roland Dreier <rolanddreier@rivian.com>

