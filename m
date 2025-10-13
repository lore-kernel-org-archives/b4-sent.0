From: Sven Peter <sven@kernel.org>
Date: Mon, 13 Oct 2025 16:03:27 +0000
Subject: [PATCH 3/5] usb: dwc3: glue: Add documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251013-b4-aplpe-dwc3-v1-3-12a78000c014@kernel.org>
References: <20251013-b4-aplpe-dwc3-v1-0-12a78000c014@kernel.org>
In-Reply-To: <20251013-b4-aplpe-dwc3-v1-0-12a78000c014@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2106; i=sven@kernel.org;
 h=from:subject:message-id; bh=b88sn5mMVCk/oe5CLT9hyAX+U6n1DTFMv6pGutiyXM0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zbpeez9SvfLDxyJURQn3vStN9Rsh5lJ2ZkP9//cuWvO
 YEbd25g7ShlYRDjYJAVU2TZvt/e9MnDN4JLN116DzOHlQlkCAMXpwBM5HUrw/+EnzNf9P47v+js
 /+//tFbfE5wZdqUi5ojfU+XvpeYO13oiGRme73yzLqXW7vGi1OxAvaxkhYrCEDNxnhXXPDIOKUj
 2B/IDAA==
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We're about to add more exported functions to be used inside glue
driver which will need more detailed documentation explaining how
they must be used. Let's also add documentation for the functions
already available.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/dwc3/glue.h | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/drivers/usb/dwc3/glue.h b/drivers/usb/dwc3/glue.h
index 2efd00e763be4fc51911f32d43054059e61fb43a..7f326cff12458901904d4c32f62ed9357d0f6e3b 100644
--- a/drivers/usb/dwc3/glue.h
+++ b/drivers/usb/dwc3/glue.h
@@ -22,9 +22,36 @@ struct dwc3_probe_data {
 	bool ignore_clocks_and_resets;
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

