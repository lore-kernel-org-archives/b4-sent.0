From: David Heidelberg <david@ixit.cz>
Date: Fri, 20 Mar 2026 17:44:46 +0100
Subject: [PATCH v7 5/7] Input: synaptics-rmi4 - don't do unaligned reads in
 IRQ context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-synaptics-rmi4-v7-5-379360de18d0@ixit.cz>
References: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
In-Reply-To: <20260320-synaptics-rmi4-v7-0-379360de18d0@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: David Heidelberg <david@ixit.cz>, linux-input@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Casey Connolly <casey.connolly@linaro.org>, phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2420; i=david@ixit.cz;
 h=from:subject:message-id; bh=zRJuDyKVtFumRqddTNRUEZ+d9fZy9eN/okm7djVZni0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvXl7OTZlkJKvt3AzFoFODIMPKidxQ6tYv0RwT
 wCCDXaLHAaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab15ewAKCRBgAj/E00kg
 ciw9EACkN9Fi59wUyHOCPN7mjIChrskAlcbQH/bJhWyBAikS8NCCGLZU95mZoJYgdjsfldzpkX+
 OzboUnWF9brUjVrnnR7CdqHz0yQGwyLwbQISAMer9uxvnoKmI7AbCFPivBjHknaZpy/BoWQzwOh
 3tZVW2jWrf4ggDeg9chp32D4VzVCy7eoCZiztuO4QDXYtJaLOL2YALXCklDyUgI1rOympHHHeuE
 cWHG2D9PX+T3I6F242Oug8pLNy4qXfRFhAjvALxmjnmuYRJpAlqGyZhyOVmVytuCu0bZ5LuZGgy
 CPrAASTLUjwLGPoyXifdFvjo0s+BZYS9oPEAAkDbaTVK6f3u3anTzgRhQqnD0MtOKfMXmBL/+SZ
 KUoy5D/KgSQI4WEwKLViShZkX0MCddoCKR6BQ8l05vnrFhMXRnAQxAvUhH1L1YOHp2gVa4YQH++
 jqGiXwYA/CEg6wT/V8xbTEO9mN9XZKKiVSaDMfF3GFHm0yfwdkCYnmC/U9jEfKoMk3J94Hv0qVU
 6tBJbScbDLWIMNlE79QjHZyYipwf5TozehdYplxUqpRuzel9kvUI+RP4elCmMFJ7bO+HZKpUYEk
 CWoXmsbPF6doh81B+Sv5dISVixA+Q3guGTaM6J1ZA7sszdZHJSt94hnMFoZmPEcfmKE5dImuZR6
 /VEw349Bx34Kzgw==
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
2.53.0

