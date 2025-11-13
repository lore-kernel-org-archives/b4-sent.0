From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 17:31:01 +0100
Subject: [PATCH v6 5/7] Input: synaptics-rmi4 - don't do unaligned reads in
 IRQ context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-synaptics-rmi4-v6-5-d9836afab801@ixit.cz>
References: <20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz>
In-Reply-To: <20251113-synaptics-rmi4-v6-0-d9836afab801@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Casey Connolly <casey.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2420; i=david@ixit.cz;
 h=from:subject:message-id; bh=2jfYK2Qe0hjHg1A0n2fWZE+x/SealRrGZEErY3nogW8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFgfJyed9yL+cvKvJ4fbUVF5fvUPdCG7sJJw9Q
 tRujzGr7WWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYHyQAKCRBgAj/E00kg
 cnJUEACjvg+R+3IThtsWYfsSlU44fwORQvlngD7TBE+p1lFPZakN2DZTgkPv/2v22gb2BIzTUsd
 kpoPmjnNmqiE/lS+PXpUdNGe3uyMGQseb1KMKxQxrXYKaaQ49Hcl8Ps9SBI+koGDlHPXSM0jIRC
 0t1Aozmxm28FgCnNXbZymwJhOH5Dny4G5NjBOFx1zmF/tyFeoD3Hm1/xADwRR7KUSYh5PGOx2Lf
 p9Stis5wcPw2HafrfmJioR/X9AFD8OG5Xwc2uOVCr2YWJkK7c0SXdHkCTFackw9NByMtAuYz+Qk
 AO3ygrdPt349yc3gJRRxsXYgA3xoleIurxoIfk/t8BL2XpVbOj8kY5yNG7zbz/n9WhGjP6xnTJB
 w6CZHVv11mvoyvHJU5+W2s85zh/HnsXwLiAQISmRlDwsuuXksmA8IDuoh6fOurUVk9j/1y4GTNI
 Vv9FrnIxm6LEkcG9Xz/D1xJ+3w37D0KJsuzOl6tXBg/UhN6bPo37XE09VZDjTh5ecLrcBO4RRdd
 7O4dtOvElE55k+lOIH9Uxeio4hIlnTyLQGR+4UOBovVJRv94h60hTpckcoccnWzRClozSP8sWO5
 1PT5HtQGpb5MXcmcuCmIXgmOVy+EG25RLVqVTvHOZcyJiTJUNqHA75KXl+p5QWVPV+w72gc98eA
 5a/UUakkugicMgg==
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
Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/input/rmi4/rmi_driver.c | 20 +++++++++++++-------
 1 file changed, 13 insertions(+), 7 deletions(-)

diff --git a/drivers/input/rmi4/rmi_driver.c b/drivers/input/rmi4/rmi_driver.c
index c7d2f68e65487..93a190e333c66 100644
--- a/drivers/input/rmi4/rmi_driver.c
+++ b/drivers/input/rmi4/rmi_driver.c
@@ -137,9 +137,14 @@ static int rmi_process_interrupt_requests(struct rmi_device *rmi_dev)
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
@@ -1079,16 +1084,17 @@ int rmi_probe_interrupts(struct rmi_driver_data *data)
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
2.51.0

