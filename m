From: Nikita Shubin <n.shubin@yadro.com>
Date: Wed, 19 Mar 2025 10:57:55 +0300
Subject: [PATCH PoC 5/7] hw/gpio/aspeed: Add gpiodev support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-gpiodev-v1-5-76da4e5800a1@yadro.com>
References: <20250319-gpiodev-v1-0-76da4e5800a1@yadro.com>
In-Reply-To: <20250319-gpiodev-v1-0-76da4e5800a1@yadro.com>
To: qemu-devel@nongnu.org
Cc: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 "Enrico Weigelt, metux IT consult" <info@metux.net>, 
 Viresh Kumar <vireshk@kernel.org>, Eric Blake <eblake@redhat.com>, 
 Markus Armbruster <armbru@redhat.com>, Michael Roth <michael.roth@amd.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, 
 =?utf-8?q?Marc-Andr=C3=A9_Lureau?= <marcandre.lureau@redhat.com>, 
 =?utf-8?q?Daniel_P=2E_Berrang=C3=A9?= <berrange@redhat.com>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>, 
 Eduardo Habkost <eduardo@habkost.net>, 
 =?utf-8?q?C=C3=A9dric_Le_Goater?= <clg@kaod.org>, 
 Peter Maydell <peter.maydell@linaro.org>, 
 Steven Lee <steven_lee@aspeedtech.com>, Troy Lee <leetroy@gmail.com>, 
 Jamin Lin <jamin_lin@aspeedtech.com>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>, Joel Stanley <joel@jms.id.au>, 
 qemu-arm@nongnu.org, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Nikita Shubin <n.shubin@yadro.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742371072; l=9057;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=LCxwVdVyHaytyw7TlHjgwh2ubyN+clkLCBd91HD+W6s=;
 b=QY/eH0K/w+TXRSupwDbLRlk8MNe53AnT+V9sWX4EEshbkn/JpR8nRJRRsJ7onmtw1mKnV0NPj
 /slWcVxjxBNDDCSgSIZCjkWz8kTwTdGE+mMjMqeXGuDuqvQhaTvi5lp
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add gpiodev support for:

- getting line info
- getting/setting lines
- monitoring line events
- monitoting config events

Binding is done via id, i.e.:

... -gpiodev chardev,id=aspeed-gpio0

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 hw/gpio/aspeed_gpio.c         | 127 ++++++++++++++++++++++++++++++++++++++++++
 include/hw/gpio/aspeed_gpio.h |   3 +
 2 files changed, 130 insertions(+)

diff --git a/hw/gpio/aspeed_gpio.c b/hw/gpio/aspeed_gpio.c
index a5b3f454e800dc9440600562b6295b069cb536fb..0c8b27c9a0cbef313254405dde3f1e1910f9bf57 100644
--- a/hw/gpio/aspeed_gpio.c
+++ b/hw/gpio/aspeed_gpio.c
@@ -291,6 +291,8 @@ static int aspeed_evaluate_irq(GPIOSets *regs, int gpio_prev_high, int gpio)
     return 0;
 }
 
+static void aspeed_gpio_line_event(AspeedGPIOState *s, uint32_t set_idx, uint32_t pin_idx);
+
 #define nested_struct_index(ta, pa, m, tb, pb) \
         (pb - ((tb *)(((char *)pa) + offsetof(ta, m))))
 
@@ -337,6 +339,9 @@ static void aspeed_gpio_update(AspeedGPIOState *s, GPIOSets *regs,
                 /* ...trigger the line-state IRQ */
                 ptrdiff_t set = aspeed_gpio_set_idx(s, regs);
                 qemu_set_irq(s->gpios[set][gpio], !!(new & mask));
+
+                /* ...notify gpio backend if any */
+                aspeed_gpio_line_event(s, set, gpio);
             } else {
                 /* ...otherwise if we meet the line's current IRQ policy... */
                 if (aspeed_evaluate_irq(regs, old & mask, gpio)) {
@@ -360,6 +365,18 @@ static bool aspeed_gpio_get_pin_level(AspeedGPIOState *s, uint32_t set_idx,
     return !!(reg_val & pin_mask);
 }
 
+static void aspeed_gpio_line_event(AspeedGPIOState *s, uint32_t set_idx, uint32_t pin_idx)
+{
+    uint32_t offset = set_idx * ASPEED_GPIOS_PER_SET + pin_idx;
+    QEMUGpioLineEvent event = GPIO_EVENT_FALLING_EDGE;
+
+    if (aspeed_gpio_get_pin_level(s, set_idx, pin_idx)) {
+        event = GPIO_EVENT_RISING_EDGE;
+    }
+
+    qemu_gpio_fe_line_event(&s->gpiodev, offset, event);
+}
+
 static void aspeed_gpio_set_pin_level(AspeedGPIOState *s, uint32_t set_idx,
                                       uint32_t pin, bool level)
 {
@@ -659,6 +676,13 @@ static uint64_t aspeed_gpio_read(void *opaque, hwaddr offset, uint32_t size)
     return value;
 }
 
+static void aspeed_gpio_config_event(AspeedGPIOState *s, uint32_t set_idx, uint32_t pin_idx)
+{
+    uint32_t offset = set_idx * ASPEED_GPIOS_PER_SET + pin_idx;
+
+    qemu_gpio_fe_config_event(&s->gpiodev, offset, GPIO_LINE_CHANGED_CONFIG);
+}
+
 static void aspeed_gpio_write_index_mode(void *opaque, hwaddr offset,
                                                 uint64_t data, uint32_t size)
 {
@@ -674,6 +698,7 @@ static void aspeed_gpio_write_index_mode(void *opaque, hwaddr offset,
     uint32_t group_idx = pin_idx / GPIOS_PER_GROUP;
     uint32_t reg_value = 0;
     uint32_t pending = 0;
+    uint32_t old_direction;
 
     set = &s->sets[set_idx];
     props = &agc->props[set_idx];
@@ -711,8 +736,12 @@ static void aspeed_gpio_write_index_mode(void *opaque, hwaddr offset,
          *  data = ( data | ~input) & output;
          */
         reg_value = (reg_value | ~props->input) & props->output;
+        old_direction = set->direction;
         set->direction = update_value_control_source(set, set->direction,
                                                      reg_value);
+        if (set->direction != old_direction) {
+            aspeed_gpio_config_event(s, set_idx, pin_idx);
+        }
         break;
     case gpio_reg_idx_interrupt:
         reg_value = set->int_enable;
@@ -813,6 +842,7 @@ static void aspeed_gpio_write(void *opaque, hwaddr offset, uint64_t data,
     const AspeedGPIOReg *reg;
     GPIOSets *set;
     uint32_t cleared;
+    uint32_t old_direction;
 
     trace_aspeed_gpio_write(offset, data);
 
@@ -867,7 +897,17 @@ static void aspeed_gpio_write(void *opaque, hwaddr offset, uint64_t data,
          *  data = ( data | ~input) & output;
          */
         data = (data | ~props->input) & props->output;
+        old_direction = set->direction;
         set->direction = update_value_control_source(set, set->direction, data);
+        qemu_log("gpio_reg_direction: 0x%x 0x%x\n", set->direction, old_direction);
+        if (set->direction != old_direction) {
+            unsigned long changed = set->direction ^ old_direction;
+            int idx = find_first_bit(&changed, ASPEED_GPIOS_PER_SET);
+            while (idx < ASPEED_GPIOS_PER_SET) {
+                aspeed_gpio_config_event(s, reg->set_idx, idx);
+                idx = find_next_bit(&changed, ASPEED_GPIOS_PER_SET, idx + 1);
+            }
+        }
         break;
     case gpio_reg_int_enable:
         set->int_enable = update_value_control_source(set, set->int_enable,
@@ -1392,11 +1432,85 @@ static void aspeed_gpio_reset(DeviceState *dev)
     memset(s->sets, 0, sizeof(s->sets));
 }
 
+static void aspeed_gpio_line_info(void *opaque, gpio_line_info *info)
+{
+    AspeedGPIOState *s = ASPEED_GPIO(opaque);
+    AspeedGPIOClass *agc = ASPEED_GPIO_GET_CLASS(s);
+    uint32_t group_idx = 0, pin_idx = 0, idx = 0;
+    uint32_t offset = info->offset;
+    const GPIOSetProperties *props;
+    bool direction;
+    const char *group;
+    int i, set_idx, grp_idx, pin;
+
+    for (i = 0; i < ASPEED_GPIO_MAX_NR_SETS; i++) {
+        props = &agc->props[i];
+        uint32_t skip = ~(props->input | props->output);
+        for (int j = 0; j < ASPEED_GPIOS_PER_SET; j++) {
+            if (skip >> j & 1) {
+                continue;
+            }
+
+            group_idx = j / GPIOS_PER_GROUP;
+            pin_idx = j % GPIOS_PER_GROUP;
+            if (idx == offset) {
+                goto found;
+            }
+
+            idx++;
+        }
+    }
+
+    return;
+
+found:
+    group = &props->group_label[group_idx][0];
+    set_idx = get_set_idx(s, group, &grp_idx);
+    snprintf(info->name, sizeof(info->name), "gpio%s%d", group, pin_idx);
+    pin =  pin_idx + group_idx * GPIOS_PER_GROUP;
+    direction = !!(s->sets[set_idx].direction & BIT_ULL(pin));
+
+    if (direction) {
+        info->flags |= GPIO_LINE_FLAG_OUTPUT;
+    } else {
+        info->flags |= GPIO_LINE_FLAG_INPUT;
+    }
+
+    qemu_log("%u: %s: set_idx=%d, grp_idx=%d, group_idx=%u, pin_idx=%u\n", offset, info->name, set_idx, grp_idx, group_idx, pin_idx);
+}
+
+static int aspeed_gpio_get_line(void *opaque, uint32_t offset)
+{
+    AspeedGPIOState *s = ASPEED_GPIO(opaque);
+    int set_idx, pin_idx;
+
+    set_idx = offset / ASPEED_GPIOS_PER_SET;
+    pin_idx = offset % ASPEED_GPIOS_PER_SET;
+
+    return aspeed_gpio_get_pin_level(s, set_idx, pin_idx);
+}
+
+static int aspeed_gpio_set_line(void *opaque, uint32_t offset, uint8_t value)
+{
+    AspeedGPIOState *s = ASPEED_GPIO(opaque);
+    int set_idx, pin_idx;
+
+    set_idx = offset / ASPEED_GPIOS_PER_SET;
+    pin_idx = offset % ASPEED_GPIOS_PER_SET;
+
+    aspeed_gpio_set_pin_level(s, set_idx, pin_idx, value);
+
+    return 0;
+}
+
 static void aspeed_gpio_realize(DeviceState *dev, Error **errp)
 {
     AspeedGPIOState *s = ASPEED_GPIO(dev);
     SysBusDevice *sbd = SYS_BUS_DEVICE(dev);
     AspeedGPIOClass *agc = ASPEED_GPIO_GET_CLASS(s);
+    DeviceState *d = DEVICE(s);
+    Object *backend;
+    Gpiodev *gpio;
 
     /* Interrupt parent line */
     sysbus_init_irq(sbd, &s->irq);
@@ -1417,6 +1531,19 @@ static void aspeed_gpio_realize(DeviceState *dev, Error **errp)
                           TYPE_ASPEED_GPIO, agc->mem_size);
 
     sysbus_init_mmio(sbd, &s->iomem);
+
+    /* NOTE: or we can create one per set */
+    if (d->id) {
+        backend = object_resolve_path_type(d->id, TYPE_GPIODEV, NULL);
+        if (backend) {
+            gpio = GPIODEV(backend);
+            qemu_gpio_fe_init(&s->gpiodev, gpio, agc->nr_gpio_pins, d->id,
+                              "ASPEED GPIO", NULL);
+            qemu_gpio_fe_set_handlers(&s->gpiodev, aspeed_gpio_line_info,
+                                      aspeed_gpio_get_line,
+                                      aspeed_gpio_set_line, s);
+        }
+    }
 }
 
 static void aspeed_gpio_init(Object *obj)
diff --git a/include/hw/gpio/aspeed_gpio.h b/include/hw/gpio/aspeed_gpio.h
index e1e6c543339ef9ddff99124d7a267e9c8544c556..f0a1207b24421f4129182fbcbb88650604313a6c 100644
--- a/include/hw/gpio/aspeed_gpio.h
+++ b/include/hw/gpio/aspeed_gpio.h
@@ -12,6 +12,8 @@
 
 #include "hw/sysbus.h"
 #include "qom/object.h"
+#include "gpiodev/gpio.h"
+#include "gpiodev/gpio-fe.h"
 
 #define TYPE_ASPEED_GPIO "aspeed.gpio"
 OBJECT_DECLARE_TYPE(AspeedGPIOState, AspeedGPIOClass, ASPEED_GPIO)
@@ -85,6 +87,7 @@ struct AspeedGPIOState {
     SysBusDevice parent;
 
     /*< public >*/
+    GpioBackend gpiodev;
     MemoryRegion iomem;
     int pending;
     qemu_irq irq;

-- 
2.45.2

