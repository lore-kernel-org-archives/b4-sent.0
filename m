From: Pawel Laszczak <pawell@cadence.com>
Date: Mon, 20 Apr 2026 12:23:57 +0200
Subject: [PATCH v2] usb: cdnsp: add support for eUSB2v2 port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260420-eusb2v2_upstream-v2-1-9883645e2ede@cadence.com>
X-B4-Tracking: v=1; b=H4sIALz+5WkC/32Nyw6CMBBFf4XM2pq2oIgr/8MQ08cgNYGSDm00h
 H+34N7lSc49dwHC4JDgWiwQMDlyfswgDwWYXo1PZM5mBsnlmVeiZhhJyyQfcaI5oBrYhZuTlo2
 qtVaQZ1PAzr335L39MUX9QjNvnc3oHc0+fPbPJDbvTz4JJlhZVtw2ttEdx5tRFkeDR+MHaNd1/
 QKQvXkmxAAAAA==
X-Change-ID: 20260417-eusb2v2_upstream-80c5b29a7bba
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 peter.chen@kernel.org, Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776680652; l=10753;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=1S2xw8eKEGUe+bnE03nIXmCBqk4ynYOJ3VbC74u7qJ0=;
 b=EOaOmceN0jXVtNJSPBaLEpPZl8pfC6bnazbbz+5n95jeeo169ydpW4V5uuKYwSNwogwSJDrzR
 CS2cysffA8vCpcIvSD6M1HrIQYaa/e2nuXxMrOyOMP/T1CFIKOdG7Bz
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Cadence CDNSP controller optionally supports eUSB2 (embedded USB2)
port. While this port type operates logically like high-speed USB 2.0,
it utilizes a different physical layer signaling.

This patch:
- Extends the port detection logic to recognize the eUSB2 protocol.
- Tracks the eUSB2 port offset in the cdnsp_device structure.
- Ensures that eUSB2 ports are correctly handled during Link State
  transitions, specifically forcing L0 when LPM is capable, similar
  to standard USB 2.0 ports.

Signed-off-by: Pawel Laszczak <pawell@cadence.com>
Acked-by: Peter Chen <peter.chen@kernel.org>
---
Changes in v2:
- Removed unnecessary space.
- Added Acked-by: Peter Chen.
---
 drivers/usb/cdns3/cdnsp-gadget.c | 49 ++++++++++++++++++---------
 drivers/usb/cdns3/cdnsp-gadget.h |  1 +
 drivers/usb/cdns3/cdnsp-mem.c    | 73 +++++++++++++++++++++++++++-------------
 drivers/usb/cdns3/cdnsp-ring.c   |  9 +++--
 4 files changed, 90 insertions(+), 42 deletions(-)

diff --git a/drivers/usb/cdns3/cdnsp-gadget.c b/drivers/usb/cdns3/cdnsp-gadget.c
index 6b3815f8a6e5..2c71c77e6ec3 100644
--- a/drivers/usb/cdns3/cdnsp-gadget.c
+++ b/drivers/usb/cdns3/cdnsp-gadget.c
@@ -124,20 +124,28 @@ void cdnsp_set_link_state(struct cdnsp_device *pdev,
 }
 
 static void cdnsp_disable_port(struct cdnsp_device *pdev,
-			       __le32 __iomem *port_regs)
+			       struct cdnsp_port *port)
 {
-	u32 temp = cdnsp_port_state_to_neutral(readl(port_regs));
+	u32 temp;
+
+	if (!port->exist)
+		return;
 
-	writel(temp | PORT_PED, port_regs);
+	temp = cdnsp_port_state_to_neutral(readl(&port->regs->portsc));
+	writel(temp | PORT_PED, &port->regs->portsc);
 }
 
 static void cdnsp_clear_port_change_bit(struct cdnsp_device *pdev,
-					__le32 __iomem *port_regs)
+					struct cdnsp_port *port)
 {
-	u32 portsc = readl(port_regs);
+	u32 portsc;
+
+	if (!port->exist)
+		return;
 
+	portsc = readl(&port->regs->portsc);
 	writel(cdnsp_port_state_to_neutral(portsc) |
-	       (portsc & PORT_CHANGE_BITS), port_regs);
+	       (portsc & PORT_CHANGE_BITS), &port->regs->portsc);
 }
 
 static void cdnsp_set_apb_timeout_value(struct cdnsp_device *pdev)
@@ -944,7 +952,7 @@ void cdnsp_set_usb2_hardware_lpm(struct cdnsp_device *pdev,
 				 struct usb_request *req,
 				 int enable)
 {
-	if (pdev->active_port != &pdev->usb2_port || !pdev->gadget.lpm_capable)
+	if (pdev->active_port == &pdev->usb3_port || !pdev->gadget.lpm_capable)
 		return;
 
 	trace_cdnsp_lpm(enable);
@@ -1310,20 +1318,26 @@ static int cdnsp_run(struct cdnsp_device *pdev,
 		break;
 	}
 
-	if (speed >= USB_SPEED_SUPER) {
+	if (pdev->usb3_port.exist && speed >= USB_SPEED_SUPER) {
 		writel(temp, &pdev->port3x_regs->mode_addr);
 		cdnsp_set_link_state(pdev, &pdev->usb3_port.regs->portsc,
 				     XDEV_RXDETECT);
 	} else {
-		cdnsp_disable_port(pdev, &pdev->usb3_port.regs->portsc);
+		cdnsp_disable_port(pdev, &pdev->usb3_port);
 	}
 
-	cdnsp_set_link_state(pdev, &pdev->usb2_port.regs->portsc,
-			     XDEV_RXDETECT);
+	if (pdev->usb2_port.exist) {
+		cdnsp_set_link_state(pdev, &pdev->usb2_port.regs->portsc,
+				     XDEV_RXDETECT);
+		writel(PORT_REG6_L1_L0_HW_EN | fs_speed, &pdev->port20_regs->port_reg6);
+	}
+
+	if (pdev->eusb_port.exist)
+		cdnsp_set_link_state(pdev, &pdev->eusb_port.regs->portsc,
+				     XDEV_RXDETECT);
 
 	cdnsp_gadget_ep0_desc.wMaxPacketSize = cpu_to_le16(512);
 
-	writel(PORT_REG6_L1_L0_HW_EN | fs_speed, &pdev->port20_regs->port_reg6);
 
 	ret = cdnsp_start(pdev);
 	if (ret) {
@@ -1469,8 +1483,10 @@ static void cdnsp_stop(struct cdnsp_device *pdev)
 			cdnsp_ep_dequeue(&pdev->eps[0], req);
 	}
 
-	cdnsp_disable_port(pdev, &pdev->usb2_port.regs->portsc);
-	cdnsp_disable_port(pdev, &pdev->usb3_port.regs->portsc);
+	cdnsp_disable_port(pdev, &pdev->usb2_port);
+	cdnsp_disable_port(pdev, &pdev->usb3_port);
+	cdnsp_disable_port(pdev, &pdev->eusb_port);
+
 	cdnsp_disable_slot(pdev);
 	cdnsp_halt(pdev);
 
@@ -1479,8 +1495,9 @@ static void cdnsp_stop(struct cdnsp_device *pdev)
 	temp = readl(&pdev->ir_set->irq_pending);
 	writel(IMAN_IE_CLEAR(temp), &pdev->ir_set->irq_pending);
 
-	cdnsp_clear_port_change_bit(pdev, &pdev->usb2_port.regs->portsc);
-	cdnsp_clear_port_change_bit(pdev, &pdev->usb3_port.regs->portsc);
+	cdnsp_clear_port_change_bit(pdev, &pdev->usb2_port);
+	cdnsp_clear_port_change_bit(pdev, &pdev->eusb_port);
+	cdnsp_clear_port_change_bit(pdev, &pdev->usb3_port);
 
 	/* Clear interrupt line */
 	temp = readl(&pdev->ir_set->irq_pending);
diff --git a/drivers/usb/cdns3/cdnsp-gadget.h b/drivers/usb/cdns3/cdnsp-gadget.h
index a91cca509db0..c44bca348a41 100644
--- a/drivers/usb/cdns3/cdnsp-gadget.h
+++ b/drivers/usb/cdns3/cdnsp-gadget.h
@@ -1474,6 +1474,7 @@ struct cdnsp_device {
 	unsigned int link_state;
 
 	struct cdnsp_port usb2_port;
+	struct cdnsp_port eusb_port;
 	struct cdnsp_port usb3_port;
 	struct cdnsp_port *active_port;
 	u16 test_mode;
diff --git a/drivers/usb/cdns3/cdnsp-mem.c b/drivers/usb/cdns3/cdnsp-mem.c
index a2a1b21f2ef8..5d8cdc91927d 100644
--- a/drivers/usb/cdns3/cdnsp-mem.c
+++ b/drivers/usb/cdns3/cdnsp-mem.c
@@ -1088,11 +1088,9 @@ void cdnsp_mem_cleanup(struct cdnsp_device *pdev)
 			  pdev->dcbaa, pdev->dcbaa->dma);
 
 	pdev->dcbaa = NULL;
-
-	pdev->usb2_port.exist = 0;
-	pdev->usb3_port.exist = 0;
-	pdev->usb2_port.port_num = 0;
-	pdev->usb3_port.port_num = 0;
+	memset(&pdev->usb2_port, 0, sizeof(struct cdnsp_port));
+	memset(&pdev->eusb_port, 0, sizeof(struct cdnsp_port));
+	memset(&pdev->usb3_port, 0, sizeof(struct cdnsp_port));
 	pdev->active_port = NULL;
 }
 
@@ -1133,6 +1131,18 @@ static void cdnsp_add_in_port(struct cdnsp_device *pdev,
 	port_offset = CDNSP_EXT_PORT_OFF(temp);
 	port_count = CDNSP_EXT_PORT_COUNT(temp);
 
+	if (port == &pdev->eusb_port) {
+		/*
+		 * If controller has usb2 + eusb port then eusb is as
+		 * second port
+		 */
+		if (port_count == 2)
+			port_offset++;
+
+		if (port_count == 1 && pdev->usb2_port.exist)
+			return;
+	}
+
 	trace_cdnsp_port_info(addr, port_offset, port_count, port->maj_rev);
 
 	port->port_num = port_offset;
@@ -1152,13 +1162,10 @@ static int cdnsp_setup_port_arrays(struct cdnsp_device *pdev)
 	base = &pdev->cap_regs->hc_capbase;
 	offset = cdnsp_find_next_ext_cap(base, 0,
 					 EXT_CAP_CFG_DEV_20PORT_CAP_ID);
-	pdev->port20_regs = base + offset;
-
-	offset = cdnsp_find_next_ext_cap(base, 0, D_XEC_CFG_3XPORT_CAP);
-	pdev->port3x_regs =  base + offset;
+	if (offset)
+		pdev->port20_regs = base + offset;
 
 	offset = 0;
-	base = &pdev->cap_regs->hc_capbase;
 
 	/* Driver expects max 2 extended protocol capability. */
 	for (i = 0; i < 2; i++) {
@@ -1173,26 +1180,46 @@ static int cdnsp_setup_port_arrays(struct cdnsp_device *pdev)
 			cdnsp_add_in_port(pdev, &pdev->usb3_port,
 					  base + offset);
 
-		if (CDNSP_EXT_PORT_MAJOR(temp) == 0x02 &&
-		    !pdev->usb2_port.port_num)
-			cdnsp_add_in_port(pdev, &pdev->usb2_port,
-					  base + offset);
+		if (CDNSP_EXT_PORT_MAJOR(temp) == 0x02) {
+			if (!pdev->usb2_port.port_num && pdev->port20_regs)
+				cdnsp_add_in_port(pdev, &pdev->usb2_port,
+						  base + offset);
+
+			if (!pdev->eusb_port.port_num)
+				cdnsp_add_in_port(pdev, &pdev->eusb_port,
+						  base + offset);
+		}
 	}
 
-	if (!pdev->usb2_port.exist || !pdev->usb3_port.exist) {
-		dev_err(pdev->dev, "Error: Only one port detected\n");
+	if (!pdev->usb2_port.exist && !pdev->eusb_port.exist &&
+	    !pdev->usb3_port.exist) {
+		dev_err(pdev->dev, "Error: No port detected\n");
 		return -ENODEV;
 	}
 
-	trace_cdnsp_init("Found USB 2.0 ports and  USB 3.0 ports.");
+	if (pdev->usb2_port.exist) {
+		pdev->usb2_port.regs = (struct cdnsp_port_regs __iomem *)
+				       (&pdev->op_regs->port_reg_base + NUM_PORT_REGS *
+					(pdev->usb2_port.port_num - 1));
+		trace_cdnsp_init("Found USB 2.0 port.");
+	}
 
-	pdev->usb2_port.regs = (struct cdnsp_port_regs __iomem *)
-			       (&pdev->op_regs->port_reg_base + NUM_PORT_REGS *
-				(pdev->usb2_port.port_num - 1));
+	if (pdev->eusb_port.exist) {
+		pdev->eusb_port.regs = (struct cdnsp_port_regs __iomem *)
+				       (&pdev->op_regs->port_reg_base + NUM_PORT_REGS *
+					(pdev->eusb_port.port_num - 1));
+		trace_cdnsp_init("Found eUSB 2.0 port.");
+	}
+
+	if (pdev->usb3_port.exist) {
+		offset = cdnsp_find_next_ext_cap(base, 0, D_XEC_CFG_3XPORT_CAP);
+		pdev->port3x_regs =  base + offset;
 
-	pdev->usb3_port.regs = (struct cdnsp_port_regs __iomem *)
-			       (&pdev->op_regs->port_reg_base + NUM_PORT_REGS *
-				(pdev->usb3_port.port_num - 1));
+		pdev->usb3_port.regs = (struct cdnsp_port_regs __iomem *)
+				       (&pdev->op_regs->port_reg_base + NUM_PORT_REGS *
+					(pdev->usb3_port.port_num - 1));
+		trace_cdnsp_init("Found USB 3.x port.");
+	}
 
 	return 0;
 }
diff --git a/drivers/usb/cdns3/cdnsp-ring.c b/drivers/usb/cdns3/cdnsp-ring.c
index 0758f171f73e..715658c981ff 100644
--- a/drivers/usb/cdns3/cdnsp-ring.c
+++ b/drivers/usb/cdns3/cdnsp-ring.c
@@ -259,7 +259,7 @@ static bool cdnsp_room_on_ring(struct cdnsp_device *pdev,
  */
 static void cdnsp_force_l0_go(struct cdnsp_device *pdev)
 {
-	if (pdev->active_port == &pdev->usb2_port && pdev->gadget.lpm_capable)
+	if (pdev->active_port != &pdev->usb3_port && pdev->gadget.lpm_capable)
 		cdnsp_set_link_state(pdev, &pdev->active_port->regs->portsc, XDEV_U0);
 }
 
@@ -763,6 +763,8 @@ static int cdnsp_update_port_id(struct cdnsp_device *pdev, u32 port_id)
 
 	if (port_id == pdev->usb2_port.port_num) {
 		port = &pdev->usb2_port;
+	} else if (port_id == pdev->eusb_port.port_num) {
+		port = &pdev->eusb_port;
 	} else if (port_id == pdev->usb3_port.port_num) {
 		port  = &pdev->usb3_port;
 	} else {
@@ -779,7 +781,8 @@ static int cdnsp_update_port_id(struct cdnsp_device *pdev, u32 port_id)
 		cdnsp_enable_slot(pdev);
 	}
 
-	if (port_id == pdev->usb2_port.port_num)
+	if ((pdev->usb2_port.exist && port_id == pdev->usb2_port.port_num) ||
+	    (pdev->eusb_port.exist && port_id == pdev->eusb_port.port_num))
 		cdnsp_set_usb2_hardware_lpm(pdev, NULL, 1);
 	else
 		writel(PORT_U1_TIMEOUT(1) | PORT_U2_TIMEOUT(1),
@@ -808,7 +811,7 @@ static void cdnsp_handle_port_status(struct cdnsp_device *pdev,
 
 	port_regs = pdev->active_port->regs;
 
-	if (port_id == pdev->usb2_port.port_num)
+	if (port_id == pdev->usb2_port.port_num || port_id == pdev->eusb_port.port_num)
 		port2 = true;
 
 new_event:

---
base-commit: 1c7cc4904160c6fc6377564140062d68a3dc93a0
change-id: 20260417-eusb2v2_upstream-80c5b29a7bba

Best regards,
--  
Pawel Laszczak <pawell@cadence.com>

