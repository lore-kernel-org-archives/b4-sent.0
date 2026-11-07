From: Rui Cao <i@udp0.com>
Date: Sat, 07 Nov 2026 18:13:43 +0800
Subject: [PATCH] spi: mt65xx: Remove the CPU latency QoS request when probe
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-mt65xx-qos-fix-v1-1-9d9c16a584e4@udp0.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNz3dwSM9OKCt3C/GLdtMwKXWOjZBPDtBRjC9OURCWgpoKiVKAw2MD
 oWAi/uDQpKzW5BGSKUm0tANz3mEtyAAAA
X-Change-ID: 20261107-mt65xx-qos-fix-32c41fd385da
To: Mark Brown <broonie@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Leilk Liu <leilk.liu@mediatek.com>
Cc: linux-spi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 stable@vger.kernel.org, Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794046428; l=2424;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=J9ck0Rmxdd1nbYdPYBN9FG+4oXVrAofA+j7Izp5hqPk=;
 b=REkzO9qjpDLtQwUJ2L7TcXugkI2yWMutN5NdD7o8ySpatBLXAbAjyDeG80TTMDedIQn2d/x9A
 T87E08PacYsCghHh8+DjFlPTrQv5tXsVOQTQ3KN19p0+P+wXDg8ZjGo
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mtk_spi_probe() adds its CPU latency QoS request before the chip select
checks, the interrupt request and spi_register_controller(), and none of
their error paths removes it again. The request is embedded in the
driver's private data, which devres frees once the probe has failed, so
the global CPU latency constraint list keeps a node in freed memory. The
next cpu_latency_qos_add_request() from any driver walks into it.

On a Redmi Note 13 5G (MT6833), an SPI controller whose probe failed the
pad_num/num_chipselect check left such a node behind, and the UFS host
adding its own request a moment later oopsed in plist_add():

Unable to handle kernel paging request at virtual address fffffffffffffff8

The same happens whenever spi_register_controller() fails, which
includes -EPROBE_DEFER while the chip select GPIOs are looked up.

Nothing needs the request before the controller is registered: only the
prepare_message() and unprepare_message() callbacks update it. Add it
just before the registration and remove it if the registration fails.

Fixes: 632556d5799a ("spi: mt65xx: add PM QoS support")
Cc: stable@vger.kernel.org
Signed-off-by: Rui Cao <i@udp0.com>
---
 drivers/spi/spi-mt65xx.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/spi/spi-mt65xx.c b/drivers/spi/spi-mt65xx.c
index b845a599f7c..49c31d4bd71 100644
--- a/drivers/spi/spi-mt65xx.c
+++ b/drivers/spi/spi-mt65xx.c
@@ -1295,8 +1295,6 @@ static int mtk_spi_probe(struct platform_device *pdev)
 		clk_disable_unprepare(mdata->spi_hclk);
 	}
 
-	cpu_latency_qos_add_request(&mdata->qos_request, PM_QOS_DEFAULT_VALUE);
-
 	if (mdata->dev_comp->need_pad_sel) {
 		if (mdata->pad_num != host->num_chipselect)
 			return dev_err_probe(dev, -EINVAL,
@@ -1323,11 +1321,13 @@ static int mtk_spi_probe(struct platform_device *pdev)
 	if (ret)
 		return dev_err_probe(dev, ret, "failed to register irq\n");
 
+	cpu_latency_qos_add_request(&mdata->qos_request, PM_QOS_DEFAULT_VALUE);
 	pm_runtime_enable(dev);
 
 	ret = spi_register_controller(host);
 	if (ret) {
 		pm_runtime_disable(dev);
+		cpu_latency_qos_remove_request(&mdata->qos_request);
 		return dev_err_probe(dev, ret, "failed to register host\n");
 	}
 

---
base-commit: d48723711bae9b8cdc56719c448ba42fef28cbee
change-id: 20261107-mt65xx-qos-fix-32c41fd385da

Best regards,
--  
Rui Cao <i@udp0.com>

