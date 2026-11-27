From: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
Date: Fri, 27 Nov 2026 19:13:07 +0900
Subject: [PATCH RFC v3 06/13] clocksource/drivers/timer-at550: add SiRF
 AT550 counter and match timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-at550-rfc-v1-v3-6-f2221008912b@gmail.com>
References: <20261127-at550-rfc-v1-v3-0-f2221008912b@gmail.com>
In-Reply-To: <20261127-at550-rfc-v1-v3-0-f2221008912b@gmail.com>
To: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Ulf Hansson <ulfh@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Linus Walleij <linusw@kernel.org>, Drew Fustini <fustini@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-doc@vger.kernel.org, soc@lists.linux.dev, 
 Yuugo Yoneda <yogo.0917.sabu@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795774399; l=5987;
 i=yogo.0917.sabu@gmail.com; s=ypl514-20261117; h=from:subject:message-id;
 bh=F+DqKHl+CH4glkcuw2di8GrhLBYm8jv5gyGPMv1ldyQ=;
 b=bdT/N8H+KPrd5O1LRRALcC5L9Rwfqk4Jq9XGOAwfSqCyTLD84MmMXi/cYkI2xz3Rf0a90ISgh
 7o6rA9nLGakCXWzxoSr6Vp/AJghoYXwIgOU4V5pyHmcHYFYJA6niIqV
X-Developer-Key: i=yogo.0917.sabu@gmail.com; a=ed25519;
 pk=TIQ8Tk4xQrxyn8rmk3GI2f5qg/kO6g2KZm7YOOyBHeg=
X-Endpoint-Received: by B4 Relay for yogo.0917.sabu@gmail.com/ypl514-20261117 with auth_id=1550
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a clocksource, sched_clock, and one-shot clockevent driver for the
SiRF AT550 system timer using the low 32-bit counter and match channel
0.

Enable the timer clock before reading the watchdog and divider
registers, preserve the firmware-configured divider, refuse to
initialize if a watchdog is running, write MATCH0 before clearing
status, implement set_state_oneshot_stopped, and unwind resources on
error.

Signed-off-by: Yuugo Yoneda <yogo.0917.sabu@gmail.com>
---
 MAINTAINERS                       |   1 +
 drivers/clocksource/Kconfig       |   6 ++
 drivers/clocksource/Makefile      |   2 +
 drivers/clocksource/timer-at550.c | 136 ++++++++++++++++++++++++++++++++++++++
 4 files changed, 145 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 3c5a814f2..d6ea4d946 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25853,6 +25853,7 @@ S:	Odd Fixes
 F:	Documentation/devicetree/bindings/arm/sirf,at550.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/sirf,at550-intc.yaml
 F:	Documentation/devicetree/bindings/timer/sirf,at550-timer.yaml
+F:	drivers/clocksource/timer-at550.c
 F:	drivers/irqchip/irq-at550.c
 
 SIS 190 ETHERNET DRIVER
diff --git a/drivers/clocksource/Kconfig b/drivers/clocksource/Kconfig
index da8348329..ed73947bd 100644
--- a/drivers/clocksource/Kconfig
+++ b/drivers/clocksource/Kconfig
@@ -835,4 +835,10 @@ choice
 
 endchoice
 
+config CLKSRC_AT550
+	bool
+	depends on ARM
+	select TIMER_OF
+	select CLKSRC_MMIO
+
 endmenu
diff --git a/drivers/clocksource/Makefile b/drivers/clocksource/Makefile
index 464ec6690..0f3d4fb1c 100644
--- a/drivers/clocksource/Makefile
+++ b/drivers/clocksource/Makefile
@@ -97,3 +97,5 @@ obj-$(CONFIG_RALINK_TIMER)		+= timer-ralink.o
 obj-$(CONFIG_NXP_STM_TIMER)		+= timer-nxp-stm.o
 obj-$(CONFIG_RTK_SYSTIMER)		+= timer-realtek.o
 obj-$(CONFIG_RZN1_TIMER)		+= timer-rzn1.o
+
+obj-$(CONFIG_CLKSRC_AT550) += timer-at550.o
diff --git a/drivers/clocksource/timer-at550.c b/drivers/clocksource/timer-at550.c
new file mode 100644
index 000000000..a56446478
--- /dev/null
+++ b/drivers/clocksource/timer-at550.c
@@ -0,0 +1,136 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* SiRF AT550 free-running counter and match channel 0. */
+#include <linux/clk.h>
+#include <linux/clockchips.h>
+#include <linux/clocksource.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/of_address.h>
+#include <linux/of_irq.h>
+#include <linux/sched_clock.h>
+
+#define AT550_MATCH0	0x08
+#define AT550_STATUS	0x20
+#define AT550_ENABLE	0x24
+#define AT550_WATCHDOG	0x28
+#define AT550_DIVIDER	0x2c
+
+static void __iomem *at550_timer;
+static struct clock_event_device at550_event;
+
+static u64 notrace at550_sched_read(void)
+{
+	return readl_relaxed(at550_timer);
+}
+
+static int at550_shutdown(struct clock_event_device *event)
+{
+	writel(0, at550_timer + AT550_ENABLE);
+	return 0;
+}
+
+static int at550_next_event(unsigned long delta,
+			    struct clock_event_device *event)
+{
+	u32 target;
+
+	writel(0, at550_timer + AT550_ENABLE);
+	target = readl(at550_timer) + delta;
+	writel(target, at550_timer + AT550_MATCH0);
+	writel(1, at550_timer + AT550_STATUS);
+	writel(1, at550_timer + AT550_ENABLE);
+	if ((s32)(target - readl(at550_timer)) <= 0) {
+		writel(0, at550_timer + AT550_ENABLE);
+		return -ETIME;
+	}
+	return 0;
+}
+
+static irqreturn_t at550_timer_interrupt(int irq, void *data)
+{
+	struct clock_event_device *event = data;
+
+	if (!(readl(at550_timer + AT550_STATUS) & 1))
+		return IRQ_NONE;
+	writel(0, at550_timer + AT550_ENABLE);
+	writel(1, at550_timer + AT550_STATUS);
+	event->event_handler(event);
+	return IRQ_HANDLED;
+}
+
+static int __init at550_timer_init(struct device_node *node)
+{
+	struct clk *clk;
+	unsigned long rate;
+	unsigned int irq;
+	int ret;
+
+	if (at550_timer)
+		return -EINVAL;
+	at550_timer = of_iomap(node, 0);
+	if (!at550_timer)
+		return -ENOMEM;
+	clk = of_clk_get(node, 0);
+	if (IS_ERR(clk)) {
+		ret = PTR_ERR(clk);
+		goto unmap;
+	}
+	ret = clk_prepare_enable(clk);
+	if (ret)
+		goto put_clock;
+	rate = clk_get_rate(clk);
+	if (!rate) {
+		ret = -EINVAL;
+		goto disable_clock;
+	}
+	/* Do not disturb a running firmware watchdog or unknown divider bits. */
+	if (readl(at550_timer + AT550_WATCHDOG) ||
+	    readl(at550_timer + AT550_DIVIDER) > 0xffff) {
+		ret = -EBUSY;
+		goto disable_clock;
+	}
+	irq = irq_of_parse_and_map(node, 0);
+	if (!irq) {
+		ret = -EINVAL;
+		goto disable_clock;
+	}
+	writel(0, at550_timer + AT550_ENABLE);
+	writel(0x3f, at550_timer + AT550_STATUS);
+	at550_event.name = "at550-match0";
+	at550_event.features = CLOCK_EVT_FEAT_ONESHOT;
+	at550_event.rating = 200;
+	at550_event.set_next_event = at550_next_event;
+	at550_event.set_state_shutdown = at550_shutdown;
+	at550_event.set_state_oneshot = at550_shutdown;
+	at550_event.set_state_oneshot_stopped = at550_shutdown;
+	at550_event.tick_resume = at550_shutdown;
+	at550_event.cpumask = cpumask_of(0);
+	at550_event.irq = irq;
+	ret = request_irq(irq, at550_timer_interrupt, IRQF_TIMER,
+			 "at550-match0", &at550_event);
+	if (ret)
+		goto dispose_irq;
+	ret = clocksource_mmio_init(at550_timer, "at550-counter", rate, 200,
+				   32, clocksource_mmio_readl_up);
+	if (ret)
+		goto free_irq;
+	/* Firmware has configured the divider; the supplied clock is its output. */
+	sched_clock_register(at550_sched_read, 32, rate);
+	clockevents_config_and_register(&at550_event, rate,
+					max(32UL, rate / 10000), 0x7fffffff);
+	return 0;
+
+free_irq:
+	free_irq(irq, &at550_event);
+dispose_irq:
+	irq_dispose_mapping(irq);
+disable_clock:
+	clk_disable_unprepare(clk);
+put_clock:
+	clk_put(clk);
+unmap:
+	iounmap(at550_timer);
+	at550_timer = NULL;
+	return ret;
+}
+TIMER_OF_DECLARE(at550, "sirf,at550-timer", at550_timer_init);

-- 
2.56.1

