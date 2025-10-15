From: Sven Peter <sven@kernel.org>
Date: Wed, 15 Oct 2025 15:40:43 +0000
Subject: [PATCH usb-next v2 3/5] usb: dwc3: glue: Add documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251015-b4-aplpe-dwc3-v2-3-cbd65a2d511a@kernel.org>
References: <20251015-b4-aplpe-dwc3-v2-0-cbd65a2d511a@kernel.org>
In-Reply-To: <20251015-b4-aplpe-dwc3-v2-0-cbd65a2d511a@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2162; i=sven@kernel.org;
 h=from:subject:message-id; bh=DMGFEJn/13K8pCwgFfOu2qPEs9uFdthFJZx/jrrxzCc=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8b7AxN27CuRbuBSvboh5cUa/m7xUK/kymuzX22YsPO2S
 PY8rfS3HaUsDGIcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJ7PJkZJh7crHvoRfbJvLK
 Ts7JCK01Spd4G1ipwDij7rP/HlbBsAhGhjlvXxvVZnCWHE7kCr7OohSv/1JYjSntzOnLVwL2GHg
 ycwEA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We're about to add more exported functions to be used inside glue
driver which will need more detailed documentation explaining how
they must be used. Let's also add documentation for the functions
already available.

Acked-by: Thinh Nguyen <Thinh.Nguyen@synopsys.com>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/dwc3/glue.h | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/drivers/usb/dwc3/glue.h b/drivers/usb/dwc3/glue.h
index cc6e138bd9ef2500215aba665300e7638f3d5214..bef4d9d68558f130f36a9088d7bb3b1220e4c048 100644
--- a/drivers/usb/dwc3/glue.h
+++ b/drivers/usb/dwc3/glue.h
@@ -36,9 +36,36 @@ struct dwc3_probe_data {
 	struct dwc3_properties properties;
 };
 
+/**
+ * dwc3_core_probe - Initialize the core dwc3 driver
+ * @data: Initialization and configuration parameters for the controller
+ *
+ * Initializes the DesignWare USB3 core driver by setting up resources,
+ * registering interrupts, performing hardware setup, and preparing
+ * the controller for operation in the appropriate mode (host, gadget,
+ * or OTG). This is the main initialization function called by glue
+ * layer drivers to set up the core controller.
+ *
+ * Return: 0 on success, negative error code on failure
+ */
 int dwc3_core_probe(const struct dwc3_probe_data *data);
+
+/**
+ * dwc3_core_remove - Deinitialize and remove the core dwc3 driver
+ * @dwc: Pointer to DWC3 controller context
+ *
+ * Cleans up resources and disables the dwc3 core driver. This should be called
+ * during driver removal or when the glue layer needs to shut down the
+ * controller completely.
+ */
 void dwc3_core_remove(struct dwc3 *dwc);
 
+/*
+ * The following callbacks are provided for glue drivers to call from their
+ * own pm callbacks provided in struct dev_pm_ops. Glue drivers can perform
+ * platform-specific work before or after calling these functions and delegate
+ * the core suspend/resume operations to the core driver.
+ */
 int dwc3_runtime_suspend(struct dwc3 *dwc);
 int dwc3_runtime_resume(struct dwc3 *dwc);
 int dwc3_runtime_idle(struct dwc3 *dwc);

-- 
2.34.1

