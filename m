From: David Heidelberg <david@ixit.cz>
Date: Sat, 08 Mar 2025 15:08:41 +0100
Subject: [PATCH v3 5/7] Input: synaptics-rmi4 - don't do unaligned reads in
 IRQ context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250308-synaptics-rmi4-v3-5-215d3e7289a2@ixit.cz>
References: <20250308-synaptics-rmi4-v3-0-215d3e7289a2@ixit.cz>
In-Reply-To: <20250308-synaptics-rmi4-v3-0-215d3e7289a2@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, methanal <baclofen@tuta.io>, 
 Caleb Connolly <caleb.connolly@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2407; i=david@ixit.cz;
 h=from:subject:message-id; bh=4xh1t3yxGMB/ipkF4g5QnA5ESuxz5T9pK1Z5a5i51vs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBnzE9qc6aq2MLr6q7eHQudH8iSzTBRNGFR0p/O2
 E7LBZU0/nqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ8xPagAKCRBgAj/E00kg
 cmGkEACL+Evc2t0oCoayy0DQ3ERGsg6j4XjsxJxnpp7FjiFuk9mVt2iOJNbH0xS/EnV92ywc9u8
 Q440LT+tFgtRezhViMsflCWQHF9lembSFsLMTsNZllrjZTakMY6Vf8r8XPBc/yqFZI3VVSUMm5q
 FCquL/Rc7DsvhkHUZaSWrB3WPZ+gnmayjA4V1t/O/UJa/0WagRgSl4BcpyqVxEMwadjQfz3YQiR
 dGnn2o9PxgdNIdVTpQYaYJhEFs5CbiqDsKe8vCrxO08xEqOQu0ds3XoRGXZib+fqaC8uigV8wQy
 j7rTbzfdQiJkIG4DJm4VUWeyKo+R1xmSLAmZqCjj75oLVyrp2ZUruz259MOYtNsS/l7/Liq/YsW
 gXDcxSu1uHueVLmSf2Y7x3F31Z8ZS9rXblpn0XQ8eSF50bEH8gzG9z2WlIzN6dnQS881drD8Jab
 vd4TON0GdHqjDgxzWVCjOT5xg5dN/Jchy/B319JfYxuiUhtWzXlPSP/4jf/iQuzV+9Wb+WUmdNp
 IVbsBgQ7IrBHzIF6k/WLSEQ5KatA5ARRbLqSaxK73ZXCq6yIZ56s3d0mSZCLrlKFkdOrgRI9Ueq
 acghTfesBUGXBQ1oRe5V0eSpinBs/Sg99Pbs5VaLJ+xYQXOhHEUtrYnya3j1+0EFXyQ/zNwG1/Q
 fxLsru3jTyOnz/w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: methanal <baclofen@tuta.io>

Some replacement displays include third-party touch ICs which incur a
significant penalty (1-2 seconds) when doing certain unaligned reads.
This is enough to break functionality when it happens in the hot path,
so adjust the interrupt handler to not read from an unaligned address.

Signed-off-by: methanal <baclofen@tuta.io>
Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
---
 drivers/input/rmi4/rmi_driver.c | 20 +++++++++++++-------
 1 file changed, 13 insertions(+), 7 deletions(-)

diff --git a/drivers/input/rmi4/rmi_driver.c b/drivers/input/rmi4/rmi_driver.c
index 51c23a407b2731d5b6eaefe9cae6288f97316e34..2790f00a58bc66c04656d0cd1b4afe9f843ee093 100644
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
@@ -1083,16 +1088,17 @@ int rmi_probe_interrupts(struct rmi_driver_data *data)
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
2.47.2

