From: Nikita Shubin <n.shubin@yadro.com>
Date: Wed, 19 Mar 2025 10:57:51 +0300
Subject: [PATCH PoC 1/7] QAPI: gpio JSON
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-gpiodev-v1-1-76da4e5800a1@yadro.com>
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
 Nikita Shubin <n.shubin@yadro.com>, Nikita Shubin <nshubin@yadro.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742371072; l=2476;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=yL5seaoNiRVlQ6Vi3YlxRJ5NFJn0Q9alBbQrrB7t0Sw=;
 b=YB9LbqclbLblyvFQXTTPw/d9jF1oOaso31QxGYcWBQPr1gC5v09w3qjV7m9K+tTJgMICur3vS
 HLPawi1W6dXBIfx7TEeM9Pftlkni22KryLNBv10MIdhlql2w9loRq7J
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nikita Shubin <nshubin@yadro.com>

Signed-off-by: Nikita Shubin <nshubin@yadro.com>
---
 qapi/gpio.json        | 68 +++++++++++++++++++++++++++++++++++++++++++++++++++
 qapi/meson.build      |  1 +
 qapi/qapi-schema.json |  1 +
 3 files changed, 70 insertions(+)

diff --git a/qapi/gpio.json b/qapi/gpio.json
new file mode 100644
index 0000000000000000000000000000000000000000..1c2b7af36813ff52cbb3a44e64a2e5a5d8658d62
--- /dev/null
+++ b/qapi/gpio.json
@@ -0,0 +1,68 @@
+# -*- Mode: Python -*-
+# vim: filetype=python
+#
+
+##
+# = Gpio devices
+##
+
+##
+# @GpiodevInfo:
+#
+# Information about a gpio device.
+#
+# @label: the label of the gpio device
+#
+# Since: 9.2
+##
+{ 'struct': 'GpiodevInfo',
+  'data': { 'label': 'str' } }
+
+##
+# @GpiodevBackendKind:
+#
+# @chardev: chardevs
+#
+# Since: 9.2
+##
+{ 'enum': 'GpiodevBackendKind',
+  'data': [ 'chardev' ] }
+
+##
+# @GpiodevChardev:
+#
+# Configuration info for chardev gpiodevs.
+#
+# @chardev: chardev id
+#
+# @size: buffer size, default is 65536
+#
+# Since: 9.2
+##
+  { 'struct': 'GpiodevChardev',
+    'data': { 'chardev': 'str',
+              '*size': 'int' } }
+
+##
+# @GpiodevChardevWrapper:
+#
+# @data: Configuration info for chardev gpiodevs
+#
+# Since: 9.2
+##
+{ 'struct': 'GpiodevChardevWrapper',
+  'data': { 'data': 'GpiodevChardev' } }
+
+##
+# @GpiodevBackend:
+#
+# Configuration info for the new chardev backend.
+#
+# @type: backend type
+#
+# Since: 9.2
+##
+{ 'union': 'GpiodevBackend',
+  'base': { 'type': 'GpiodevBackendKind' },
+  'discriminator': 'type',
+  'data': { 'chardev': 'GpiodevChardevWrapper' } }
\ No newline at end of file
diff --git a/qapi/meson.build b/qapi/meson.build
index eadde4db307f0c54a7a1f2471a063c78346810cc..13d255adb8e6d823356fe0ecae0b585688320f9d 100644
--- a/qapi/meson.build
+++ b/qapi/meson.build
@@ -35,6 +35,7 @@ qapi_all_modules = [
   'dump',
   'ebpf',
   'error',
+  'gpio',
   'introspect',
   'job',
   'machine-common',
diff --git a/qapi/qapi-schema.json b/qapi/qapi-schema.json
index 2877aff73d0caff9d4ed681de0690c24a268cecd..03cfa1ed4a0438d00a6151d56167ec929467f15d 100644
--- a/qapi/qapi-schema.json
+++ b/qapi/qapi-schema.json
@@ -52,6 +52,7 @@
 { 'include': 'block-export.json' }
 { 'include': 'char.json' }
 { 'include': 'dump.json' }
+{ 'include': 'gpio.json' }
 { 'include': 'net.json' }
 { 'include': 'ebpf.json' }
 { 'include': 'rocker.json' }

-- 
2.45.2

