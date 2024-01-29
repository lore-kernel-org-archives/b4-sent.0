From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 29 Jan 2024 14:44:15 +0000
Subject: [PATCH BlueZ v4 1/8] configure, README: introduce
 --enable-external-plugins
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240129-rm-ext-plugins-v4-1-bfd1e08c7f99@gmail.com>
References: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
In-Reply-To: <20240129-rm-ext-plugins-v4-0-bfd1e08c7f99@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706539455; l=2129;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=TURnkD96L8lhhZthFxY3kbYoSxFEDANByCVJaEdcrOg=;
 b=OfKLp3lmunDbO7SjD7ptcG7Qsp0A7Ef092N5KC4EjC4bBBcdkUFQCFyaIcEUTotTlBf02WBHn
 7UV3hCvEGk6CYNaD3JY5SPTRt1b06qFnO4HHESYYrIJybQz3D97ktHG
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

As the README chunk says, disabled by default, since they rely on
internal API/ABI and can break at any point.

Instead everyone affected should work and upstream their plugin into the
bluez project.
---
 README       | 13 +++++++++++++
 configure.ac | 10 ++++++++++
 2 files changed, 23 insertions(+)

diff --git a/README b/README
index 7de7045a8..6c0777046 100644
--- a/README
+++ b/README
@@ -249,6 +249,19 @@ For a working system, certain configuration options need to be enabled:
 		systems. The behavior of the deprecated tools may be unstable
 		or simply don't work anymore.
 
+	--enable-external-plugins
+
+		Enable support for external plugins
+
+		By default external plugins for bluetoothd and obexd are not
+		supported and thus disabled.
+
+		External plugins require access to internal, undocumented and
+		unversioned API in said daemons. As such they can break at any
+		time. If you have such plugins, enable this option and work
+		actively with the community to make said plugin part of the
+		upstream bluez project.
+
 	--enable-nfc
 
 		This option enable NFC pairing support.
diff --git a/configure.ac b/configure.ac
index b4d362494..5eb7ee0e0 100644
--- a/configure.ac
+++ b/configure.ac
@@ -364,6 +364,16 @@ AC_ARG_ENABLE(deprecated, AS_HELP_STRING([--enable-deprecated],
 					[enable_deprecated=${enableval}])
 AM_CONDITIONAL(DEPRECATED, test "${enable_deprecated}" = "yes")
 
+AC_ARG_ENABLE(external-plugsin, AS_HELP_STRING([--enable-external-plugins],
+			[enable support for external plugins]),
+					[enable_external_plugins=${enableval}])
+AM_CONDITIONAL(EXTERNAL_PLUGINS, test "${enable_external_plugins}" = "yes")
+if (test "${enable_external_plugins}" = "yes"); then
+	AC_DEFINE(EXTERNAL_PLUGINS, 1, [Define if external plugin support is required])
+else
+	AC_DEFINE(EXTERNAL_PLUGINS, 0, [Define if external plugin support is required])
+fi
+
 AC_ARG_ENABLE(sixaxis, AS_HELP_STRING([--enable-sixaxis],
 		[enable sixaxis plugin]), [enable_sixaxis=${enableval}])
 AM_CONDITIONAL(SIXAXIS, test "${enable_sixaxis}" = "yes" &&

-- 
2.43.0

