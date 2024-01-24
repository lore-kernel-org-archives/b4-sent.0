From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 24 Jan 2024 16:07:57 +0000
Subject: [PATCH BlueZ v2 1/8] configure, README: introduce
 --enable-external-plugins
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240124-rm-ext-plugins-v2-1-5244906f05ff@gmail.com>
References: <20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com>
In-Reply-To: <20240124-rm-ext-plugins-v2-0-5244906f05ff@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706112482; l=2129;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=e1EdDSyciHHAaX9NsOJkW3suqFVoEXcg0Cnn7chU+j0=;
 b=wZYVhXk4d+d1zkJHhssGBaY6vQuhV8G7N+2hDdjZ4AbMKP4XBklm6/NB0S+YGw4naiNCcfYp1
 9iEoJaO+Q4dAXGqgVsncGI6PhasTNvUJVlUoT8B35gtqTmUOWvxodpa
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
index cab5da581..5e353a1d6 100644
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

