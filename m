From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 20:44:56 +0200
Subject: [PATCH v4 5/7] Input: synaptics-rmi4 - don't do unaligned reads in
 IRQ context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-synaptics-rmi4-v4-5-1bb95959e564@ixit.cz>
References: <20250402-synaptics-rmi4-v4-0-1bb95959e564@ixit.cz>
In-Reply-To: <20250402-synaptics-rmi4-v4-0-1bb95959e564@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Caleb Connolly <caleb.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2474; i=david@ixit.cz;
 h=from:subject:message-id; bh=yMLuXgF9v/gFFJ+eFIvXnbQst25n9j3YV0dhX4KqpyU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7YWn/MP81rV9Ai3YBRmaVNbv+GCZaR4aqY8Z2
 7jKtV2jv1mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2FpwAKCRBgAj/E00kg
 ch3REACV+Sw+Ehcsl6co/1yutsFO8jpuFKCjDFYaX4X6PuILT97X2sBpBeAKvgyNFcWy681SsSe
 zPDFNVwnh5jAnAHdvCTqPV8GJToSnkdSgQzsBsUfVbGAq1ZY9nnPcSWOAGwjmR3RHRZ7mpYWkEN
 7lGt9njfD/bj6iNIv/HtxgMgMz1fXBH/9FlbcXo8WZrHIUtPx1RcM+6vW0hiUgf0C+S51jh9BRr
 BQt1BpWuFcDEjOXNW1h4rFMmpYtn7iJdzCTSfcdVfO7ww3F9W8+bnpTroW9kZo1kc7EmxYautjk
 hH88dXFZumwqNxV0xSwvbhDafbf9HmbjmNsqNjdUoHAWReSiSoOvbTFBYKWxPrOp+IeRDJUWvBP
 GqBVzDZr+XW5n7P0EUG9WdIoOuveOCEtYE5jHSkdRjRedi0EeZpuy43sfF5/0FvhU1JJHWk83la
 /Uiz5Q2q4zqRLWlCGei4XBZEoss81akGlx5G3ueWV8ei/bfngI7v/OUpwz/GEoNGxDblf1Dacpp
 MEYWFWWphPMPdBU9Ese9kb1QSa1sY8vYUkii8r62AqOL5K9Vcw1RG8gYPSXvqZDnVGjA7YcF+lR
 POKMqFWZQjoUQuL5p3eJZYQRZnHACAINO79XWG74qPBQLVlM4mRBKh5Fo2At9MHhq8L4WVPLLjL
 z/sYSD5zCZcG92g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kaustabh Chakraborty <kauschluss@disroot.org>

Some replacement displays include third-party touch ICs which incur a
significant penalty (1-2 seconds) when doing certain unaligned reads.
This is enough to break functionality when it happens in the hot path,
so adjust the interrupt handler to not read from an unaligned address.

Signed-off-by: Kaustabh Chakraborty <kauschluss@disroot.org>
Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_driver.c | 20 +++++++++++++-------
 1 file changed, 13 insertions(+), 7 deletions(-)

diff --git a/drivers/input/rmi4/rmi_driver.c b/drivers/input/rmi4/rmi_driver.c
index 0f6dbe586c652d641178f43ec27df3613126ca66..f977541d8913525d53a59e1d53c33897f1c93901 100644
--- a/drivers/input/rmi4/rmi_driver.c
+++ b/drivers/input/rmi4/rmi_driver.c
@@ -136,9 +136,14 @@ static int rmi_process_interrupt_requests(struct rmi_device *rmi_dev)
 		return 0;
 
 	if (!data->attn_data.data) {
+		/*
+		 * Read the device status register as well and ignore it.
+		 * Some aftermarket ICs have issues with interrupt requests
+		 * otherwise.
+		 */
 		error = rmi_read_block(rmi_dev,
-				data->f01_container->fd.data_base_addr + 1,
-				data->irq_status, data->num_of_irq_regs);
+				data->f01_container->fd.data_base_addr,
+				(u8 *)data->irq_status - 1, data->num_of_irq_regs + 1);
 		if (error < 0) {
 			dev_err(dev, "Failed to read irqs, code=%d\n", error);
 			return error;
@@ -1078,16 +1083,17 @@ int rmi_probe_interrupts(struct rmi_driver_data *data)
 	data->num_of_irq_regs = (data->irq_count + 7) / 8;
 
 	size = BITS_TO_LONGS(data->irq_count) * sizeof(unsigned long);
-	data->irq_memory = devm_kcalloc(dev, size, 4, GFP_KERNEL);
+	data->irq_memory = devm_kzalloc(dev, size * 4 + 1, GFP_KERNEL);
 	if (!data->irq_memory) {
 		dev_err(dev, "Failed to allocate memory for irq masks.\n");
 		return -ENOMEM;
 	}
 
-	data->irq_status	= data->irq_memory + size * 0;
-	data->fn_irq_bits	= data->irq_memory + size * 1;
-	data->current_irq_mask	= data->irq_memory + size * 2;
-	data->new_irq_mask	= data->irq_memory + size * 3;
+	/* The first byte is reserved for the device status register */
+	data->irq_status	= data->irq_memory + size * 0 + 1;
+	data->fn_irq_bits	= data->irq_memory + size * 1 + 1;
+	data->current_irq_mask	= data->irq_memory + size * 2 + 1;
+	data->new_irq_mask	= data->irq_memory + size * 3 + 1;
 
 	return retval;
 }

-- 
2.49.0

