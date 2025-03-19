From: Nikita Shubin <n.shubin@yadro.com>
Subject: [PATCH PoC 0/7] Interact with QEMU GPIO models via gpiodev
Date: Wed, 19 Mar 2025 10:57:50 +0300
Message-Id: <20250319-gpiodev-v1-0-76da4e5800a1@yadro.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP542mcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDY0Nj3fSCzPyU1DLdFCOTVLMUy6RUS4MUJaDqgqLUtMwKsEnRSgH5zkq
 xtbUAQ3Bxql4AAAA=
X-Change-ID: 20250313-gpiodev-d24e6d9be90d
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
 Nikita Shubin <n.shubin@yadro.com>, Nikita Shubin <nshubin@yadro.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742371072; l=8121;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=v6D5JRyAnkEXhNSj1IxdOf5lQh2CIRszHVIVcqqm/q8=;
 b=smyhmZ+DO2v7RqLAXne+93BmqpsPyGB0E0NlfUVWtCjrzH8ASKDXELWc0P0WyjWPYKrHVvpY0
 vQZ+U9kNf13BONq4OHnt/j0tO4y2qLsYgu/kLzEtOiTX1Lw7G+QnPEw
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While vhost-user-gpio-pci is a good solution to pass gpios inside guest
it still doesn't cover the following cases:

- AFAIK the board needs to have a PCI bus;
- we add new hot-plugged gpios instead of re-using the existing ones;
- we can't connect it to existing gpio models;

This functionality is quite desired (numerous emails observed 
since i released https://github.com/maquefel/virtual_gpio_basic which 
is ivshmem based and have same disadvantages as above) - the ability 
to manipulate existing gpios, including MMIO mmaped like 
aspeed or bcm2835/bcm2838 gpios.

This becomes even more important for MCUs where virtio gpio application
is limited.

For example:

https://stackoverflow.com/questions/76834038/qemu-gpio-connect
https://stackoverflow.com/questions/60764018/how-to-connect-gpio-in-qemu-emulated-machine-to-an-object-in-host

And so on.

So the most obvious thing is to create something similar to existing
chardev, to provide common interface for models to interact with.

I propose new gpiodev, which consists of gpiodev itself, frontend
and backends just like chardev does.

It provides the abilities which mostly replicate the current
state of Linux GPIO UAPI, i.e.:

- getting GPIO chip/line info;
- monitoring line state change externally on rising/falling events;
- monitoring configuration change (output swith to input and vise-versa);
- setting/getting gpio pins;

The interface for GPIO Models is described in qemu/include/gpiodev/gpio-fe.h.

The model should provide callbacks for the following:

- LineInfoHandler to provide info aboud line specified by offset;
- LineGetValueHandler to get gpio line value specified by offset;
- LineGetValueHandler to set gpio line value specified by offset;

Also the model can notify the Gpiodev and connected back about:

- line value;
- line config;

changed by the guest witch qemu_gpio_fe_line_event()/qemu_gpio_fe_config_event().

A nice choice for demonstation purpose as heavily used and, maybe,
the most full board simulation in QEMU.

It seems to have some flaws in GPIO model hovewer (not sure if it's really a flaw through).

Andrew provided some clarification on Linux driver implementation, and
agreed that it might be a bug in QEMU model.

First write to pin has no effect to gpiomon/gpio-event-mon as direction is set AFTER pin value
which results in qemu_gpio_fe_line_event() not called in aspeed_gpio_update(),
so qemu_set_irq() won't be called for the same reason by the way.

```
aspeed # gpioset 0 8=1
aspeed_gpio_write offset: 0x1c value 0x100
aspeed_gpio_write offset: 0x0 value 0x100       <-- VALUE
aspeed_gpio_write offset: 0x4 value 0x100       <-- DIRECTION
```

Also ast2600 machine was modified to set DEVICE()->id for gpios, as ASPEED gpio relies
on this to connect to gpiodev.

A simple backend over any chadev transport, while this solution seems good at first glance,
it lacks solid protocol (currently used Linux GPIO UAPI structs) and I couldn't find any
suitable/standardized solution, something like MOXA uses for ioLogik devices for example.
So using this backend requires specials tools like qemu-gpio-tools (just Linux gpio tools
with some modification for demo purpose).

I someone can propose a ready protocol or an idea please do so.

Some demo interacting with ASPEED:

```
host $ build-qemu/qemu-system-arm -M ast2600-evb,bmc-console=uart5 -kernel buildroot/output/build/linux-6.6.14/arch/arm/boot/zImage \
-dtb buildroot/output/build/linux-6.6.14/arch/arm/boot/dts/aspeed/aspeed-ast2600-evb.dtb \
-initrd buildroot/output/images/rootfs.cpio -nographic -serial mon:stdio \
-gpiodev chardev,id=aspeed-gpio0,chardev=gpio0 -chardev socket,path=/tmp/gpio0,id=gpio0,server=on,wait=off
```

```
host $ qemu-gpio-tools/lsgpio -n /tmp/gpio0
sending 0x8044b401
GPIO chip: aspeed-gpio0, "ASPEED GPIO", 208 GPIO lines
        line  0: "gpioA0" unused [input]
        line  1: "gpioA1" unused [input]
        line  2: "gpioA2" unused [input]
        line  3: "gpioA3" unused [input]
        line  4: "gpioA4" unused [input]
        line  5: "gpioA5" unused [input]
        line  6: "gpioA6" unused [input]
        line  7: "gpioA7" unused [input]
        line  8: "gpioB0" unused [input]
[...]
        line 200: "gpioZ0" unused [input]
        line 201: "gpioZ1" unused [input]
        line 202: "gpioZ2" unused [input]
        line 203: "gpioZ3" unused [input]
        line 204: "gpioZ4" unused [input]
        line 205: "gpioZ5" unused [input]
        line 206: "gpioZ6" unused [input]
        line 207: "gpioZ7" unused [input]
```

I did some experiments with CUSE, but it lacks the most important functionality,
creating new file descriptors (creating new file could also do). While it's quite simple
to implement something like sysfs GPIO i don't think it's a good solution (hehehehehe, Bartosz and Linus i hope you appreciate this),
so i decided to make something similiar to CUSE.

The price is high:

- a kernel module (also kernel modifitions are also required to make it pretty - export fuse_mknod function for example);
- new guse bindings for libfuse;
- libgpiod modification (a small one to allow "/sys/class/guse" in gpiod_check_gpiochip_device());
- and the QEMU of course;

But i was obsessed with the idea of using the same tools like in Linux (libgpiod for example ;)),
and still it was a fun thing to do.

With this we can have a FULL support of Linux GPIO UAPI.

Module ony test with 6.11.*, v6.13.*+ (pages replaced with folio) under KSAN, kmemleak.

```
$ sudo insmod guse/guse.ko
```

```
sudo build-qemu/qemu-system-arm -M ast2600-evb,bmc-console=uart5 -kernel buildroot/output/build/linux-6.6.14/arch/arm/boot/zImage \
-dtb buildroot/output/build/linux-6.6.14/arch/arm/boot/dts/aspeed/aspeed-ast2600-evb.dtb \
-initrd buildroot/output/images/rootfs.cpio -nographic -serial mon:stdio -gpiodev guse,id=aspeed-gpio0,devname=gpiochip10
```

```
aspeed # gpioset 0 8=1
aspeed # gpioget 0 8
```

```
host $ sudo libgpiod/tools/gpionotify -c 10 8
1741686422.149345616    reconfigured    aspeed-gpio0 8
1741686430.466103054    reconfigured    aspeed-gpio0 8
```

```
aspeed # gpioset 0 8=1
aspeed # gpioset 0 8=0
```

```
$ sudo libgpiod/tools/gpiomon -c 10 8
1741687220.025006346    rising  aspeed-gpio0 8
1741687222.634353601    falling aspeed-gpio0 8
```

gpio-sim also can serve as a backend, but the only thing we can get from
it is monitoring lines set by QEMU guest. So i didn't bother
implementing it yet.

I prepare a suite with whing nessary if someone wants to test/tinker
with current series:

Link: git://git.maquefel.me/qemu-gpiodev/qemu-guse-suite.git

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
Nikita Shubin (7):
      QAPI: gpio JSON
      Add gpiodev dummy
      gpiodev: Add GPIO device frontend
      gpiodev: Add GPIO backend over chardev
      hw/gpio/aspeed: Add gpiodev support
      hw/arm: ast2600: set id for gpio
      gpiodev: Add gpiobackend over GUSE

 gpiodev/gpio-chardev.c        | 479 +++++++++++++++++++++++++++
 gpiodev/gpio-fe.c             | 103 ++++++
 gpiodev/gpio-guse.c           | 747 ++++++++++++++++++++++++++++++++++++++++++
 gpiodev/gpio.c                | 399 ++++++++++++++++++++++
 gpiodev/meson.build           |   8 +
 hw/arm/aspeed_ast2600.c       |   2 +
 hw/gpio/aspeed_gpio.c         | 127 +++++++
 include/gpiodev/gpio-fe.h     | 122 +++++++
 include/gpiodev/gpio.h        | 233 +++++++++++++
 include/hw/gpio/aspeed_gpio.h |   3 +
 meson.build                   |  11 +-
 qapi/gpio.json                |  93 ++++++
 qapi/meson.build              |   1 +
 qapi/qapi-schema.json         |   1 +
 qemu-options.hx               |   9 +
 qom/object.c                  |   1 +
 system/vl.c                   |  25 ++
 17 files changed, 2363 insertions(+), 1 deletion(-)
---
base-commit: 98c7362b1efe651327385a25874a73e008c6549e
change-id: 20250313-gpiodev-d24e6d9be90d

Best regards,
-- 
Nikita Shubin <n.shubin@yadro.com>

