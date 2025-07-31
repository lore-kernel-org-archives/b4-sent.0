From: David Heidelberg <david@ixit.cz>
Date: Thu, 31 Jul 2025 23:06:55 +0200
Subject: [PATCH RESEND v5 5/7] Input: synaptics-rmi4 - don't do unaligned
 reads in IRQ context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-synaptics-rmi4-v5-5-cd0d87d34afa@ixit.cz>
References: <20250731-synaptics-rmi4-v5-0-cd0d87d34afa@ixit.cz>
In-Reply-To: <20250731-synaptics-rmi4-v5-0-cd0d87d34afa@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Casey Connolly <casey.connolly@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2474; i=david@ixit.cz;
 h=from:subject:message-id; bh=Nyz1YCbWJwORQMBcpF1SBjXVXtSklYzZW6mP61MM2z8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi9r/1r/PGC5D4fNDIHK0ZJt7U7Uz62vLzmrqS
 W0YSzM6coSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIva/wAKCRBgAj/E00kg
 cp8wD/94hEgArL13OukACP2YpcKMvJt/pO6G6oxP/GZnOfc9AVvNtvc69nL4mEmegxGdS/xANnz
 L6vt04au0PGH3ks6ChAyxwjqClqGPQ8tKj5obtadGQ7RYcwJP5UYU9OZvqbcy2iEf8x06nasksl
 BRkpCOeyrkACowwJrv6/fF4r3e9c3x0ITfLA3h8hdl+74kWr5RQTd7zBJrVuYnwIBWe7D0E/4Ap
 0zcuBu+jxAt4/T9mNK8nJOJqBgUpz88EsYfWjQ1hJc06VcAHoH6BZE7aGjmk0Ymn1E5kWKwqY7p
 XKazQlqNLmP/YTAhcVUWUQT4nwZMaIXLkQA/VwsH5YVURFCSRQU9hBKVF9/D3r4XMb+S+Y/HEh6
 EhpkfMalE2Vk2A/r0qcS4cWDREQcEV0FVu4kg9w35XwCbQqjbJi6YvbSjkonzmV6RgFvT2hHpRM
 i573xePIsX9OJLqqA72kqfnxdwjCY/krSi4794czhqG1MDasmCepJfOiABlBZEvsL02vkJY85oD
 2yq2qvi1Rn4u7ind5nOUewJPL6x/7aKx9RRSfgkt8JfM+mAxTIYPbiFrYx0J6dijVSkmCkK2FCS
 EolWi9GYX/csI0hLvnabYpW+pCs/vsW1zxmoeoBIKlJYXdEqpHwO87PNY6BoiHmPE3bG3RcsKIT
 nUHEQoCFCPkmXhQ==
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
2.50.1

