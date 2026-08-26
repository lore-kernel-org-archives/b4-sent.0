From: Pawel Laszczak <pawell@cadence.com>
Date: Wed, 26 Aug 2026 13:24:38 +0200
Subject: [PATCH v2 3/3] usb: cdns3: cdnsp: Enable eUSB2v2 1KB bulk packet
 capability
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260826-eusb2v2-packet-size-v2-3-950f19f38ef0@cadence.com>
References: <20260826-eusb2v2-packet-size-v2-0-950f19f38ef0@cadence.com>
In-Reply-To: <20260826-eusb2v2-packet-size-v2-0-950f19f38ef0@cadence.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Mathias Nyman <mathias.nyman@intel.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787743495; l=4597;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=fzuaIRwsep0I/yQ38o8xT1m/qQPyfCzKgU+SbDae//E=;
 b=/emCebuQHyWB8uZXci9RNMGI7SUDsVxo/gcDTeOPbeayDCSjkfPSsqe7gc/1VP6NFAywCFebt
 /LGbesGa6tuBAXTpbSV+l1Pe1UT15J2yaG+1Xqs/EFk2EWgkGEERd/w
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement peripheral-side changes in the Cadence (cdnsp) driver
to support eUSB2v2 1024-byte Bulk MaxPacketSize.

Check the HCC2_E2V2C bit in HCCPARAMS2 during setup and set
'pdev->gadget.is_eusb2v2 = 1' if supported. Update cdnsp_endpoint_init()
to allow internal max_packet size allocation up to 1024 bytes for HS
Bulk endpoints, and delegate the incoming update setup request from
ep0 to the composite layer.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
Changes in v2:
- cdnsp-mem.c: simplified HS bulk clamp logic to: if (max_packet != 1024)
  max_packet = 512, consistent with xhci-mem.c.
---
 drivers/usb/cdns3/cdnsp-ep0.c    |  2 ++
 drivers/usb/cdns3/cdnsp-gadget.c |  4 ++++
 drivers/usb/cdns3/cdnsp-gadget.h |  8 ++++++++
 drivers/usb/cdns3/cdnsp-mem.c    | 10 ++++++++--
 drivers/usb/common/debug.c       |  2 ++
 5 files changed, 24 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/cdns3/cdnsp-ep0.c b/drivers/usb/cdns3/cdnsp-ep0.c
index 5cd9b898ce97..090d20b307ee 100644
--- a/drivers/usb/cdns3/cdnsp-ep0.c
+++ b/drivers/usb/cdns3/cdnsp-ep0.c
@@ -253,6 +253,8 @@ static int cdnsp_ep0_handle_feature_device(struct cdnsp_device *pdev,
 		 */
 		cdnsp_enter_test_mode(pdev);
 		break;
+	case USB_DEVICE_BULK_MAX_PACKET_UPDATE:
+		return cdnsp_ep0_delegate_req(pdev, ctrl);
 	default:
 		return -EINVAL;
 	}
diff --git a/drivers/usb/cdns3/cdnsp-gadget.c b/drivers/usb/cdns3/cdnsp-gadget.c
index a5275c2fb43b..ac1dde43ce1d 100644
--- a/drivers/usb/cdns3/cdnsp-gadget.c
+++ b/drivers/usb/cdns3/cdnsp-gadget.c
@@ -1853,6 +1853,10 @@ static int cdnsp_gen_setup(struct cdnsp_device *pdev)
 	pdev->hcc_params = readl(&pdev->cap_regs->hc_capbase);
 	pdev->hci_version = HC_VERSION(pdev->hcc_params);
 	pdev->hcc_params = readl(&pdev->cap_regs->hcc_params);
+	pdev->hcc_params2 = readl(&pdev->cap_regs->hcc_params2);
+
+	if (pdev->hcc_params2 & HCC2_E2V2C)
+		pdev->gadget.is_eusb2v2 = 1;
 
 	/*
 	 * Override the APB timeout value to give the controller more time for
diff --git a/drivers/usb/cdns3/cdnsp-gadget.h b/drivers/usb/cdns3/cdnsp-gadget.h
index c44bca348a41..75bc3f15bde5 100644
--- a/drivers/usb/cdns3/cdnsp-gadget.h
+++ b/drivers/usb/cdns3/cdnsp-gadget.h
@@ -89,6 +89,12 @@ struct cdnsp_cap_regs {
 
 #define CTX_SIZE(_hcc)		(HCC_64BYTE_CONTEXT(_hcc) ? 64 : 32)
 
+/* HCCPARAMS2 - hcc_params2 - bitmasks */
+/* bit 11 - DC support Double BW on a eUSB2 HS ISOC EP */
+#define HCC2_EUSB2_DIC		BIT(11)
+/* bit 12 - DC support eUSB2V2 capability */
+#define HCC2_E2V2C		BIT(12)
+
 /* db_off bitmask - bits 0:1 reserved. */
 #define DBOFF_MASK	GENMASK(31, 2)
 
@@ -1370,6 +1376,7 @@ struct cdnsp_port {
  * @rev_cap: Controller Capabilities Registers.
  * @hcs_params1: Cached register copies of read-only HCSPARAMS1
  * @hcc_params: Cached register copies of read-only HCCPARAMS1
+ * @hcc_params2: Cached register copies of read-only HCCPARAMS2
  * @rtl_revision: Cached controller rtl revision.
  * @setup: Temporary buffer for setup packet.
  * @ep0_preq: Internal allocated request used during enumeration.
@@ -1425,6 +1432,7 @@ struct cdnsp_device {
 	__u32 hcs_params1;
 	__u32 hcs_params3;
 	__u32 hcc_params;
+	__u32 hcc_params2;
 	#define RTL_REVISION_NEW_LPM 0x2700
 	__u32 rtl_revision;
 	/* Lock used in interrupt thread context. */
diff --git a/drivers/usb/cdns3/cdnsp-mem.c b/drivers/usb/cdns3/cdnsp-mem.c
index 5d8cdc91927d..e9f205cb1dac 100644
--- a/drivers/usb/cdns3/cdnsp-mem.c
+++ b/drivers/usb/cdns3/cdnsp-mem.c
@@ -978,8 +978,14 @@ int cdnsp_endpoint_init(struct cdnsp_device *pdev,
 	if (!usb_endpoint_xfer_isoc(pep->endpoint.desc))
 		err_count = 3;
 	if (usb_endpoint_xfer_bulk(pep->endpoint.desc) &&
-	    pdev->gadget.speed == USB_SPEED_HIGH)
-		max_packet = 512;
+	    pdev->gadget.speed == USB_SPEED_HIGH) {
+		if (!pdev->gadget.is_eusb2v2)
+			max_packet = 512;
+		else
+			if (max_packet != 1024)
+				max_packet = 512;
+	}
+
 	/* Controller spec indicates that ctrl ep avg TRB Length should be 8. */
 	if (usb_endpoint_xfer_control(pep->endpoint.desc))
 		avg_trb_len = 8;
diff --git a/drivers/usb/common/debug.c b/drivers/usb/common/debug.c
index f204cec8d380..b9696fae7ef5 100644
--- a/drivers/usb/common/debug.c
+++ b/drivers/usb/common/debug.c
@@ -46,6 +46,8 @@ static const char *usb_decode_device_feature(u16 wValue)
 		return "U2 Enable";
 	case USB_DEVICE_LTM_ENABLE:
 		return "LTM Enable";
+	case USB_DEVICE_BULK_MAX_PACKET_UPDATE:
+		return "Bulk mps update";
 	default:
 		return "UNKNOWN";
 	}

-- 
2.43.0

